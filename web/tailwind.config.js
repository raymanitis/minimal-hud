/* eslint-disable no-undef */
export default {
    darkMode: ["class"],
    content: [
        "./pages/**/*.{ts,tsx}",
        "./components/**/*.{ts,tsx}",
        "./app/**/*.{ts,tsx}",
        "./src/**/*.{ts,tsx}",
    ],
    theme: {
        fontFamily: {
            sans: [
                "Nexa-Book",
                "ui-sans-serif",
                "system-ui",
                "sans-serif",
                "Apple Color Emoji",
                "Segoe UI Emoji",
                "Segoe UI Symbol",
                "Noto Color Emoji",
            ],
        },
        extend: {
            textShadow: {
                sm: "0 1px 2px var(--tw-shadow-color)",
                DEFAULT: "0 2px 4px var(--tw-shadow-color)",
                lg: "0 8px 16px var(--tw-shadow-color)",
            },
            fontFamily: {
                nexa: [
                    "Nexa-Book",
                    "ui-sans-serif",
                    "system-ui",
                    "sans-serif",
                    "Apple Color Emoji",
                    "Segoe UI Emoji",
                    "Segoe UI Symbol",
                    "Noto Color Emoji",
                ],
                montserrat: [
                    "Montserrat",
                    "ui-sans-serif",
                    "system-ui",
                    "sans-serif",
                    "Apple Color Emoji",
                    "Segoe UI Emoji",
                    "Segoe UI Symbol",
                    "Noto Color Emoji",
                ],
                geist: [
                    "Geist",
                    "ui-sans-serif",
                    "system-ui",
                    "sans-serif",
                    "Apple Color Emoji",
                    "Segoe UI Emoji",
                    "Segoe UI Symbol",
                    "Noto Color Emoji",
                ],
                roboto: ["Roboto", "sans-serif"],
                oswald: ["Oswald", "sans-serif"],
                inter: ["Inter", "sans-serif"],
            },
            screens: {
                1920: "1920px",
                "2k": "2560px",
                "4k": "3840px",
            },
            colors: {
                /* yume colours */
                y_white: "#F2F2F2",
                y_black: "#0A0A0A",
                y_orange: "#FB8607",
                y_pink: "#FE247B",
                y_blue: "#2B78FC",
                y_green: "#228BE6",
                y_red: "#FE2436",
                primary: "#228BE6", /* mantine blue */
                border: "#434346", /* grey */
                secondaryBorder: "#646260", /* light */
                gradientDark: {
                    from: "#3c3a3c7a",
                    via: "#3c3a3cc7",
                    to: "#3c3a3c7a",
                },
                gradientMuted: {
                    from: "#5a585662",
                    via: "#5a58569f",
                    to: "#5a585662",
                },
            },
        },
    },
    plugins: [],
};
