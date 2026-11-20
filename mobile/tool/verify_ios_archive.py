#!/usr/bin/env python3
"""Check iOS launch configuration, device executables, and archive signatures."""
import plistlib
from pathlib import Path
import re
import subprocess
import sys


def verify(archive: Path) -> None:
    apps = list((archive / "Products/Applications").glob("*.app"))
    if len(apps) != 1:
        raise ValueError("Expected one app in the .xcarchive")
    app = apps[0]
    with (app / "Info.plist").open("rb") as source:
        info = plistlib.load(source)
    scenes = (
        info.get("UIApplicationSceneManifest", {})
        .get("UISceneConfigurations", {})
        .get("UIWindowSceneSessionRoleApplication", [])
    )
    if not any(
        scene.get("UISceneDelegateClassName") == "FlutterSceneDelegate"
        and scene.get("UISceneStoryboardFile") == "Main"
        for scene in scenes
    ):
        raise ValueError("Missing Flutter UIScene launch configuration required by iOS 27")
    if not (app / "Base.lproj" / "Main.storyboardc").is_dir():
        raise ValueError("Missing compiled Main storyboard used by the launch scene")

    bundles = [app, *app.rglob("*.framework"), *app.rglob("*.appex")]
    failures = []
    for bundle in bundles:
        with (bundle / "Info.plist").open("rb") as source:
            executable = plistlib.load(source)["CFBundleExecutable"]
        binary = bundle / executable
        architectures = subprocess.check_output(
            ["xcrun", "lipo", "-archs", str(binary)], text=True
        ).split()
        build = subprocess.check_output(
            ["xcrun", "vtool", "-show-build", str(binary)], text=True
        )
        platforms = re.findall(r"\bplatform\s+(\S+)", build)
        device_platform = (
            all(platform == "IOS" for platform in platforms)
            if platforms
            else "LC_VERSION_MIN_IPHONEOS" in build
        )
        if not device_platform or not set(architectures) <= {"arm64", "arm64e"}:
            failures.append(f"{bundle.name}: {architectures}, {platforms}")
    if failures:
        raise ValueError("Non-device executable(s):\n" + "\n".join(failures))
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    print(f"PASS: Flutter UIScene configured; {len(bundles)} signed iOS device bundles")


if __name__ == "__main__":
    try:
        verify(Path(sys.argv[1]))
    except (IndexError, ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
