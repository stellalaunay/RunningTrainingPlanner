//
//  LoginView.swift
//  RunningTrainingPlanner
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    let authManager: AuthManager

    @State private var isSignUp = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    // Random nonce generated before each Apple Sign-In request; verified server-side by Firebase
    @State private var currentNonce: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // App title and mode label
                VStack(spacing: 6) {
                    Text("RunPlan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appAccent)
                    if isSignUp {
                        Text("Create your account")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 60)

                // Input fields
                VStack(spacing: 12) {
                    // Name fields — only shown during sign-up
                    if isSignUp {
                        HStack(spacing: 12) {
                            TextField("First name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Last name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Error message shown below fields
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Email/password button
                Button {
                    Task { await emailPasswordAction() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Sign Up" : "Log In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(formIsValid ? Color.appAccent : Color.appAccent.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(isLoading || !formIsValid)

                // Divider between email and social login options
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                    Text("or").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                }
                .padding(.horizontal)

                // Google sign-in button — custom to center the logo and text
                Button {
                    Task { await signInWithGoogle() }
                } label: {
                    HStack(spacing: 12) {
                        Image("google_logo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(red: 0.235, green: 0.251, blue: 0.263))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(.systemGray4), lineWidth: 0.5))
                }
                .padding(.horizontal)

                // Apple sign-in button
                SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    // Apple requires a hashed version of the nonce
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    Task { await handleAppleSignIn(result: result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .padding(.horizontal)

                // Toggle between log in and sign up
                Button {
                    isSignUp.toggle()
                    errorMessage = nil
                } label: {
                    Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundStyle(Color.appAccent)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // Sign-up requires all four fields; log-in requires email and password
    private var formIsValid: Bool {
        if isSignUp {
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty
        }
        return !email.isEmpty && !password.isEmpty
    }

    // MARK: - Email/password auth

    private func emailPasswordAction() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if isSignUp {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                await createBackendUser(
                    firebaseUid: result.user.uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: email
                )
            } else {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign-In

    private func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else { return }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google sign-in failed: missing token"
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            // Create a backend record for new Google users using their Google profile
            if authResult.additionalUserInfo?.isNewUser == true {
                let profile = result.user.profile
                await createBackendUser(
                    firebaseUid: authResult.user.uid,
                    firstName: profile?.givenName ?? "",
                    lastName: profile?.familyName ?? "",
                    email: profile?.email ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign-In

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Apple sign-in failed: missing credential"
                return
            }
            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                // Apple only provides the user's name on the very first sign-in ever
                if authResult.additionalUserInfo?.isNewUser == true {
                    await createBackendUser(
                        firebaseUid: authResult.user.uid,
                        firstName: appleCredential.fullName?.givenName ?? "",
                        lastName: appleCredential.fullName?.familyName ?? "",
                        email: appleCredential.email ?? ""
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Backend user creation

    // Creates a user record in the backend after Firebase sign-up completes.
    // firebase_uid is extracted from the auth token server-side, so only name fields are needed here.
    private func createBackendUser(firebaseUid: String, firstName: String, lastName: String, email: String) async {
        do {
            try await APIService.createUser(firstName: firstName, lastName: lastName)
        } catch {
            // Non-fatal — Firebase account still exists; backend record can be retried later
        }
    }

    // MARK: - Apple Sign-In nonce helpers

    // Generates a cryptographically random nonce string required by Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var byte: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
                return byte
            }
            for byte in randoms {
                guard remaining > 0 else { break }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    // SHA-256 hash of the nonce — sent to Apple so they can verify it matches what Firebase receives
    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}


#Preview {
    LoginView(authManager: AuthManager())
}
