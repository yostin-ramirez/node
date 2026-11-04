pragma Singleton
import QtQuick

QtObject {
    readonly property int baseUnit: 4

    readonly property var space: ({
            100: baseUnit,
            150: baseUnit * 1.5,
            200: baseUnit * 2,
            300: baseUnit * 3,
            400: baseUnit * 4,
            500: baseUnit * 5,
            600: baseUnit * 6
        })

    readonly property var radius: ({
            100: baseUnit,
            150: baseUnit * 1.5,
            200: baseUnit * 2,
            250: baseUnit * 2.5,
            300: baseUnit * 3,
            350: baseUnit * 3.5,
            400: baseUnit * 4,
            500: baseUnit * 5,
            600: baseUnit * 6
        })

    readonly property var size: ({
            100: baseUnit,
            400: baseUnit * 4,
            600: baseUnit * 6,
            650: baseUnit * 6.5,
            1200: baseUnit * 12,
            1600: baseUnit * 16
        })

    // Radius scale
    readonly property int radiusSmall: radius[150]
    readonly property int radiusMedium: radius[250]

    // Stroke
    readonly property int borderThin: 1

    // Spacing
    readonly property int spacingSmall: space[150]
    readonly property int spacingMedium: space[200]
    readonly property int spacingLarge: space[400]

    // Sizes
    readonly property int iconSmall: size[400]
    readonly property int iconMedium: size[600]
    readonly property int iconLarge: size[1200]
}
