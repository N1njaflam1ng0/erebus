// The lockscreen shell. Adapted from qylock's quickshell-lockscreen/lock_shell.qml
// (Darkkal44/qylock, GPLv3) -- the WlSessionLock plumbing and the SddmShim contract
// are theirs. Two deliberate departures:
//
//  * `config` comes from ThemeConfig.qml, which _lock.nix generates from the
//    theme's own conf at build time. qylock's shim fetches theme.conf with an
//    ASYNC XMLHttpRequest whose onreadystatechange never fires under quickshell,
//    so `config` stays {} and every colour, font and dimension in the theme reads
//    back undefined. Baking it in removes the runtime read entirely.
//
//  * `keyboard` is stubbed. sddm-astronaut's Components/Input.qml reads
//    keyboard.capsLock; nothing here can tell, and an undefined identifier is a
//    ReferenceError rather than a quiet undefined, which takes the login-failed
//    warning down with it.
//
// Everything the theme resolves -- config, keyboard, sddm, userModel, sessionModel
// -- has to be a property of this root: the theme is loaded by URL, and a Loader's
// object gets a context that chains up to the loading component's scope.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "./shim"

ShellRoot {
    id: shellRoot

    // Set by the erebus-lock wrapper; the theme lives next to this file.
    property string themePath: Quickshell.env("QS_THEME_PATH") || (Quickshell.shellDir + "/theme")

    readonly property var config: themeConfig.values
    readonly property var keyboard: QtObject { readonly property bool capsLock: false }

    readonly property var sddm: sddmShim.sddm
    readonly property var userModel: sddmShim.userModel
    readonly property var sessionModel: sddmShim.sessionModel

    readonly property bool isWayland: Quickshell.env("XDG_SESSION_TYPE") === "wayland"
    // Renders the theme in a 1280x720 window instead of taking a session lock, so
    // the thing can be looked at without locking the seat:
    //   XDG_SESSION_TYPE=x11 QS_TESTING=1 erebus-lock
    readonly property bool isTesting: Quickshell.env("QS_TESTING") === "1"

    property bool authenticated: false
    property bool sessionLocked: true

    ThemeConfig { id: themeConfig }

    // Still qylock's: PamContext auth behind an sddm-shaped object, plus the
    // userModel/sessionModel the theme's ComboBoxes bind to. Its own config
    // loader is left unused -- hence the empty themePath.
    SddmShim {
        id: sddmShim
        themePath: ""
    }

    Connections {
        target: sddmShim.sddm
        function onLoginSucceeded() {
            shellRoot.authenticated = true;
            if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "")
                Quickshell.execDetached(["hyprctl", "keyword", "misc:allow_session_lock_restore", "1"]);
            Quickshell.execDetached(["loginctl", "unlock-session"]);
            quitTimer.start();
        }
    }

    Timer {
        id: quitTimer
        interval: 100
        onTriggered: {
            shellRoot.sessionLocked = false;
            Qt.quit();
        }
    }

    Component {
        id: themeComponent

        Loader {
            anchors.fill: parent
            source: "file://" + shellRoot.themePath + "/Main.qml"

            onLoaded: item.forceActiveFocus()
            onStatusChanged: if (status === Loader.Error) console.error("FAILED to load theme:", source)
        }
    }

    Loader {
        active: shellRoot.isWayland
        sourceComponent: Component {
            WlSessionLock {
                locked: shellRoot.sessionLocked

                surface: Component {
                    WlSessionLockSurface {
                        color: "black"

                        // Absorb unhandled gestures so nothing reaches through.
                        PinchHandler { target: null }
                        WheelHandler { target: null }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            hoverEnabled: true
                            onWheel: wheel => wheel.accepted = true
                        }

                        Loader {
                            anchors.fill: parent
                            sourceComponent: themeComponent
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: !shellRoot.isWayland
        sourceComponent: Component {
            Variants {
                model: Quickshell.screens

                delegate: Window {
                    required property var modelData

                    // No `screen:` -- Quickshell.screens hands out QuickshellScreenInfo, which
                    // Window.screen will not take. This branch only exists to look at the
                    // theme in a window, so one screen is enough.
                    width: shellRoot.isTesting ? 1280 : screen.width
                    height: shellRoot.isTesting ? 720 : screen.height
                    visible: shellRoot.sessionLocked
                    visibility: shellRoot.isTesting ? Window.Windowed : Window.FullScreen
                    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.MaximizeUsingFullscreenGeometryHint
                    color: "black"

                    onClosing: close => close.accepted = shellRoot.authenticated || shellRoot.isTesting

                    Loader {
                        anchors.fill: parent
                        sourceComponent: themeComponent
                    }
                }
            }
        }
    }
}
