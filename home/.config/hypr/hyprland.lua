------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
hl.exec_cmd("waybar")
hl.exec_cmd("hyprpaper")
hl.exec_cmd("mako")
hl.exec_cmd("/usr/lib/hyprpolkitagent")
hl.exec_cmd("hypridle")
hl.exec_cmd("/home/lucifer/.local/bin/refresh-switch")
hl.exec_cmd("wl-paste --watch cliphist store")
hl.exec_cmd("nm-applet --indicator")
hl.exec_cmd("/home/lucifer/.local/bin/battery-watch")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
---hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:00:02.0-card")---
-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 4,
        border_size = 1,

        col = {
            active_border   = "rgba(ffffffff)",
          inactive_border = "rgba(1a1a1aff)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = false,
    },

    misc = {
        force_default_wallpaper  = 0,
            disable_hyprland_logo    = true,
            disable_splash_rendering = true,
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll   = true,

        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Core application binds
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind("Print",         hl.dsp.exec_cmd("/home/lucifer/.local/bin/shot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("/home/lucifer/.local/bin/shot-edit"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd('sh -c "cliphist list | rofi -dmenu | cliphist decode | wl-copy"'))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("/home/lucifer/.config/rofi/powermenu.sh"))
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + bracketleft",  hl.dsp.group.prev())
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Window navigation
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    -- Mouse binds
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Audio & Brightness
    hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

    -- Media keys
    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

    --------------------------------
    ---- WINDOWS AND WORKSPACES ----
    --------------------------------
    hl.window_rule({
        name           = "suppress-maximize-events",
        match          = { class = ".*" },
        suppress_event = "maximize",
    })

    hl.window_rule({
        name  = "fix-xwayland-drags",
        match = {
            class      = "^$",
            title      = "^$",
            xwayland   = true,
            float      = true,
            fullscreen = false,
            pin        = false,
        },
        no_focus = true,
    })

-------------------------------
---- HyDE-STYLE WINDOW BINDS ----
-------------------------------
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Z", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + X", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 30,  y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -30, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })

-- Screen recording
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd("/home/lucifer/.local/bin/rec-toggle region"))
hl.bind(mainMod .. " + ALT + R",   hl.dsp.exec_cmd("/home/lucifer/.local/bin/rec-toggle full"))
