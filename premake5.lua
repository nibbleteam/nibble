workspace "PongBoy"
    configurations { "Debug", "Release" }

project "PongBoy"
    kind "WindowedApp"
    language "C++"
    targetdir "bin/%{cfg.buildcfg}"

    libdirs {
        "extern/sfml/build/lib/"
    }

    includedirs {
        "extern/sfml/include/",
        "include/",
    }

    files {
        "src/**.cpp",
    }

    links {
        "sfml-window-s",
        "sfml-system-s",
        "sfml-network-s",
        "sfml-graphics-s",
        "sfml-audio-s",
    }

    filter "Linux"
        system "Linux"

        links {
            "pthread",
            "X11",
            "GL",
            "Xrandr",
            "udev"
        }

    filter "configurations:Debug"
        defines { "DEBUG" }
        symbols "On"

    filter "configurations:Release"
        defines { "RELEASE" }
        optimize "On"
