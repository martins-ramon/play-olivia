#!/usr/bin/env python3
"""Generate the dependency-free Xcode project from OliviaPlay's source tree."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "OliviaPlay"
PROJECT = ROOT / "OliviaPlay.xcodeproj"
objects: dict[str, dict] = {}


def identifier(name: str) -> str:
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def add(object_name: str, **values) -> str:
    key = identifier(object_name)
    objects[key] = values
    return key


def file_type(path: Path) -> str:
    return {
        ".swift": "sourcecode.swift",
        ".plist": "text.plist.xml",
        ".xcassets": "folder.assetcatalog",
        ".xcprivacy": "text.xml",
        ".mp3": "audio.mp3",
        ".wav": "audio.wav",
        ".m4a": "audio.m4a",
        ".png": "image.png",
        ".jpg": "image.jpeg",
        ".json": "text.json",
    }.get(path.suffix.lower(), "file")


source_builds: list[str] = []
resource_builds: list[str] = []


def group(path: Path) -> str:
    children = []
    for entry in sorted(path.iterdir(), key=lambda item: (not item.is_dir(), item.name)):
        if entry.name.startswith("."):
            continue
        if entry.is_dir() and entry.suffix != ".xcassets":
            children.append(group(entry))
            continue
        relative = entry.relative_to(ROOT).as_posix()
        ref = add(relative, isa="PBXFileReference", lastKnownFileType=file_type(entry),
                  path=entry.name, sourceTree="<group>")
        children.append(ref)
        if entry.suffix == ".swift":
            source_builds.append(add("build:" + relative, isa="PBXBuildFile", fileRef=ref))
        elif "Resources" in entry.relative_to(SOURCE).parts:
            resource_builds.append(add("build:" + relative, isa="PBXBuildFile", fileRef=ref))
    return add("group:" + path.relative_to(ROOT).as_posix(), isa="PBXGroup",
               children=children, path=path.name, sourceTree="<group>")


def encode(value, level=0) -> str:
    indent = "\t" * level
    if isinstance(value, dict):
        lines = ["{"]
        for key, item in value.items():
            lines.append(f"{indent}\t{json.dumps(str(key))} = {encode(item, level + 1)};")
        lines.append(indent + "}")
        return "\n".join(lines)
    if isinstance(value, list):
        if not value:
            return "()"
        return "(\n" + "".join(f"{indent}\t{encode(item, level + 1)},\n" for item in value) + indent + ")"
    return json.dumps(str(value), ensure_ascii=False)


def main() -> None:
    # Preserve the two account-specific values a parent may have set in Xcode.
    # Never read signing certificates or account credentials.
    saved_signing = {}
    existing_project = PROJECT / "project.pbxproj"
    if existing_project.exists():
        try:
            previous = json.loads(subprocess.check_output(
                ["plutil", "-convert", "json", "-o", "-", str(existing_project)],
                stderr=subprocess.DEVNULL))
            for name in ("Debug", "Release"):
                settings = previous["objects"].get(identifier("target:" + name), {}).get("buildSettings", {})
                saved_signing[name] = {key: settings[key] for key in
                                      ("DEVELOPMENT_TEAM", "PRODUCT_BUNDLE_IDENTIFIER") if settings.get(key)}
        except (OSError, subprocess.CalledProcessError, KeyError, ValueError):
            pass
    SOURCE.mkdir(exist_ok=True)
    app_group = group(SOURCE)
    product = add("product", isa="PBXFileReference", explicitFileType="wrapper.application",
                  includeInIndex=0, path="OliviaPlay.app", sourceTree="BUILT_PRODUCTS_DIR")
    products = add("products", isa="PBXGroup", children=[product], name="Products", sourceTree="<group>")
    main_group = add("main", isa="PBXGroup", children=[app_group, products], sourceTree="<group>")
    source_phase = add("sources", isa="PBXSourcesBuildPhase", buildActionMask=2147483647,
                       files=source_builds, runOnlyForDeploymentPostprocessing=0)
    resource_phase = add("resources", isa="PBXResourcesBuildPhase", buildActionMask=2147483647,
                         files=resource_builds, runOnlyForDeploymentPostprocessing=0)
    framework_phase = add("frameworks", isa="PBXFrameworksBuildPhase", buildActionMask=2147483647,
                          files=[], runOnlyForDeploymentPostprocessing=0)
    common = {
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    }
    project_configs = []
    target_configs = []
    for name in ("Debug", "Release"):
        project_settings = dict(common)
        project_settings.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf" if name == "Debug" else "dwarf-with-dsym",
            "ENABLE_TESTABILITY": "YES" if name == "Debug" else "NO",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if name == "Debug" else "-O",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)" if name == "Debug" else "$(inherited)",
        })
        project_configs.append(add("project:" + name, isa="XCBuildConfiguration", name=name, buildSettings=project_settings))
        target_settings = {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "5",
            "GENERATE_INFOPLIST_FILE": "NO",
            "INFOPLIST_FILE": "OliviaPlay/Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
            "MARKETING_VERSION": "1.4",
            "PRODUCT_BUNDLE_IDENTIFIER": "br.com.oliviaplay.app",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
            "SUPPORTS_MACCATALYST": "NO",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "TARGETED_DEVICE_FAMILY": "2",
        }
        target_settings.update(saved_signing.get(name, {}))
        target_configs.append(add("target:" + name, isa="XCBuildConfiguration", name=name, buildSettings=target_settings))
    project_list = add("project:configurations", isa="XCConfigurationList", buildConfigurations=project_configs,
                       defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
    target_list = add("target:configurations", isa="XCConfigurationList", buildConfigurations=target_configs,
                      defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
    target = add("target", isa="PBXNativeTarget", buildConfigurationList=target_list,
                 buildPhases=[source_phase, framework_phase, resource_phase], buildRules=[], dependencies=[],
                 name="OliviaPlay", productName="OliviaPlay", productReference=product,
                 productType="com.apple.product-type.application")
    project = add("project", isa="PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "1600"},
                  buildConfigurationList=project_list, compatibilityVersion="Xcode 14.0", developmentRegion="pt-BR",
                  hasScannedForEncodings=0, knownRegions=["pt-BR", "en", "Base"], mainGroup=main_group,
                  productRefGroup=products, projectDirPath="", projectRoot="", targets=[target])
    PROJECT.mkdir(exist_ok=True)
    payload = {"archiveVersion": 1, "classes": {}, "objectVersion": 56,
               "objects": objects, "rootObject": project}
    (PROJECT / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode(payload) + "\n")
    scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="OliviaPlay.app" BlueprintName="OliviaPlay" ReferencedContainer="container:OliviaPlay.xcodeproj"/>'
    scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="NO">
    <BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
    (scheme_dir / "OliviaPlay.xcscheme").write_text(scheme)
    print(f"Projeto atualizado: {len(source_builds)} arquivos Swift, {len(resource_builds)} recursos.")


if __name__ == "__main__":
    main()
