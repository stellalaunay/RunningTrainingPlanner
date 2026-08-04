//
//  ColorPalettes.swift
//  RunningTrainingPlanner
//
//  Color palettes for experimenting with the app's visual theme.
//  To switch palettes, change the AppPalette typealias — one line, whole app updates.

import SwiftUI

// MARK: - Active palette
typealias AppPalette = GreenPalette

// MARK: - Theme color roles (used throughout the app)
extension Color {
    static var appAccent: Color         { AppPalette.accent }
    static var appCardBackground: Color { AppPalette.cardBackground }
    static var appTodayCard: Color      { AppPalette.todayCard }
}

// MARK: - Palette protocol
protocol ColorPalette {
    static var accent: Color { get }
    static var cardBackground: Color { get }
    static var todayCard: Color { get }
}

// MARK: - Palette 1: Teal (original)
struct TealPalette: ColorPalette {
    static let accent         = Color(red: 0.161, green: 0.663, blue: 0.710) // #29A9B5
    static let cardBackground = Color(red: 0.933, green: 0.969, blue: 0.973)
    static let todayCard      = Color(red: 0.820, green: 0.937, blue: 0.945)
}

// MARK: - Palette 2: Blue Gradient
struct BluePalette: ColorPalette {
    static let accent         = Color(red: 0.373, green: 0.525, blue: 0.651) // #5F86A6 Dusty Denim
    static let cardBackground = Color(red: 0.929, green: 0.957, blue: 0.980) // #EDF4FA Cloud Blue
    static let todayCard      = Color(red: 0.812, green: 0.890, blue: 0.945) // #CFE3F1 Powder Sky

    static let cloudBlue    = Color(red: 0.929, green: 0.957, blue: 0.980)
    static let powderSky    = Color(red: 0.812, green: 0.890, blue: 0.945)
    static let calmOcean    = Color(red: 0.561, green: 0.714, blue: 0.847)
    static let dustyDenim   = Color(red: 0.373, green: 0.525, blue: 0.651)
    static let midnightBlue = Color(red: 0.141, green: 0.227, blue: 0.369)
}

// MARK: - Palette 3: Earthy
struct EarthyPalette: ColorPalette {
    static let accent         = Color(red: 0.533, green: 0.565, blue: 0.388) // #889063 Moss Green
    static let cardBackground = Color(red: 0.898, green: 0.843, blue: 0.769) // #E5D7C4 Bone
    static let todayCard      = Color(red: 0.812, green: 0.733, blue: 0.600) // #CFBB99 Tan

    static let cafeNoir   = Color(red: 0.298, green: 0.239, blue: 0.098)
    static let kombuGreen = Color(red: 0.208, green: 0.251, blue: 0.141)
    static let mossGreen  = Color(red: 0.533, green: 0.565, blue: 0.388)
    static let tan        = Color(red: 0.812, green: 0.733, blue: 0.600)
    static let bone       = Color(red: 0.898, green: 0.843, blue: 0.769)
}

// MARK: - Palette 4: Matcha Green
struct MatchaPalette: ColorPalette {
    static let accent         = Color(red: 0.475, green: 0.596, blue: 0.318) // #799851 Palm Leaf
    static let cardBackground = Color(red: 0.875, green: 0.867, blue: 0.820) // #DFDDD1 Timberwolf
    static let todayCard      = Color(red: 0.624, green: 0.722, blue: 0.471) // #9FB878 Olivine

    static let timberwolf    = Color(red: 0.875, green: 0.867, blue: 0.820)
    static let olivine       = Color(red: 0.624, green: 0.722, blue: 0.471)
    static let palmLeaf      = Color(red: 0.475, green: 0.596, blue: 0.318)
    static let darkMossGreen = Color(red: 0.278, green: 0.384, blue: 0.165)
    static let kombuGreen    = Color(red: 0.216, green: 0.267, blue: 0.149)
}

// MARK: - Palette 5: Soft Mix (blue, green, pink, cream)
struct SoftMixPalette: ColorPalette {
    static let accent         = Color(red: 0.706, green: 0.416, blue: 0.447) // #B46A72 Rosewood
    static let cardBackground = Color(red: 1.000, green: 0.969, blue: 0.902) // #FFF7E6 Vanilla Cream
    static let todayCard      = Color(red: 0.969, green: 0.784, blue: 0.827) // #F7C8D3 Blush Petal

    static let vanillaCream   = Color(red: 1.000, green: 0.969, blue: 0.902)
    static let blushPetal     = Color(red: 0.969, green: 0.784, blue: 0.827)
    static let rosewood       = Color(red: 0.706, green: 0.416, blue: 0.447)
    static let sageLeaf       = Color(red: 0.659, green: 0.710, blue: 0.541)
    static let mistySky       = Color(red: 0.663, green: 0.718, blue: 0.776)
    static let midnightLagoon = Color(red: 0.176, green: 0.227, blue: 0.278)
}

// MARK: - Palette 6: Green
struct GreenPalette: ColorPalette {
    static let accent         = Color(red: 0.388, green: 0.639, blue: 0.263) // mid green for buttons/circles
    static let cardBackground = Color(red: 0.910, green: 0.961, blue: 0.886) // #E8F5E2 very light green
    static let todayCard      = Color(red: 0.737, green: 0.878, blue: 0.667) // #BCE0AA medium green
}

// MARK: - Palette 7: Pink
struct PinkPalette: ColorPalette {
    static let accent         = Color(red: 0.820, green: 0.337, blue: 0.455) // deep pink for buttons/circles
    static let cardBackground = Color(red: 0.996, green: 0.922, blue: 0.937) // #FEEBEFvery light pink
    static let todayCard      = Color(red: 0.973, green: 0.737, blue: 0.796) // #F8BCCB medium pink
}
