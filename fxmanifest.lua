fx_version "cerulean"
game "gta5"

shared_scripts({
    "@ox_lib/init.lua",
    -- "require.lua",
    "init.lua",
})
-- ox_libs {
--     'cache'
-- }

ui_page("dist/index.html")
-- ui_page("http://localhost:5173/") test

files({
    "dist/index.html",
    "dist/assets/*.js",
    "dist/assets/*.css",
    "dist/**/*.woff2",
    "config/*.lua",
    "modules/interface/client.lua",
    "modules/utility/shared/logger.lua",
    "modules/utility/shared/main.lua",
    "modules/frameworks/**/*.lua",
    "modules/threads/client/**/*.lua",
})

-- Logo is now included in the web build as logo.png

lua54 "yes"
use_experimental_fxv2_oal("yes")
nui_callback_strict_mode("true")
