#!/usr/bin/env python3
"""Reject simulator code in an App Store archive before an upload consumes time."""
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
    print(f"PASS: {len(bundles)} signed bundles contain iOS device code only")


if __name__ == "__main__":
    try:
        verify(Path(sys.argv[1]))
    except (IndexError, ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
