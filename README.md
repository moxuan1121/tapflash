# TapFlash

RootHide arm64e tweak for iOS 15.

- Double-click the side button to toggle play/pause.
- Triple-click the side button to toggle the flashlight.
- The triple-click replaces the system Accessibility Shortcut action.

## Required setting

Open **Settings → Accessibility → Accessibility Shortcut** and select at least one shortcut. iOS then enables its native multi-click side-button recognizer; TapFlash intercepts the completed double/triple-click actions.

## Build

The GitHub Actions workflow builds an `iphoneos-arm64e` RootHide package and uploads the generated `.deb` as an artifact.
