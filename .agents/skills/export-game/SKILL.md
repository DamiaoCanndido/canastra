---
name: export-game
description: >-
  Defines how the DevOps & Export Master agent (@devops) builds, tests, packages, and exports Godot 4 games across platforms (Web, Linux, Windows, Mobile) using headless CLI and CI/CD pipelines.
---

# Export Game

**Skill for:** `@devops`

## Purpose

Defines how the DevOps & Export Master agent takes verified game builds approved by `@qa` and automates headless testing, cross-platform compilation, asset optimization, and distribution packaging in Godot Engine 4.

## When to use

- Preparing a release candidate or production build after `@qa` sign-off.
- Setting up or maintaining CI/CD pipelines for automated builds and testing.
- Configuring `export_presets.cfg` for desktop (Linux/Windows/macOS), Web (HTML5/WASM), or Mobile.
- Troubleshooting export template errors, asset compression issues, or Web SharedArrayBuffer compatibility.

## Process

1. **Confirm QA Sign-Off** — Verify all test suites pass and no blocker or major bugs remain open.
2. **Validate Export Configuration** — Ensure `export_presets.cfg` exists with properly configured target paths and release settings.
3. **Execute Headless Test Suite** — Run all automated test suites via Godot CLI before initiating compilation.
4. **Build & Export Targets** — Invoke Godot in headless export mode for target platforms.
5. **Optimize & Package Assets** — Verify texture compression (VRAM/ETC2/ASTC), strip debug symbols, and bundle release `.pck` files.
6. **Web Server Header Verification** — For Web exports, verify that the hosting environment sets required headers (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`).
7. **Generate Checksums & Artifacts** — Produce SHA256 checksums for all release binaries and upload artifacts.

## Godot 4 CLI & Build Automation

### 1. Headless Test Execution
```bash
# Run test suite headlessly in Godot 4
godot --headless --script res://test/run_tests.gd --quit
```

### 2. Headless Export Commands
```bash
# Export Web (HTML5/WASM)
mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html

# Export Linux Desktop
mkdir -p build/linux
godot --headless --export-release "Linux/X11" build/linux/canastra.x86_64

# Export Windows Desktop
mkdir -p build/windows
godot --headless --export-release "Windows Desktop" build/windows/canastra.exe
```

### 3. GitHub Actions CI/CD Pipeline Template (`.github/workflows/build.yml`)
```yaml
name: Godot 4 CI/CD Export

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3
    steps:
      - uses: actions/checkout@v4
      - name: Run Headless Tests
        run: |
          godot --headless --script res://test/run_tests.gd

  export:
    needs: test
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3
    steps:
      - uses: actions/checkout@v4
      - name: Setup Export Directory
        run: mkdir -v -p build/web build/linux build/windows
      - name: Export Web
        run: godot --headless --export-release "Web" build/web/index.html
      - name: Export Linux
        run: godot --headless --export-release "Linux/X11" build/linux/canastra.x86_64
      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: game-builds
          path: build/
```

## Release Checklist

```markdown
- [ ] Automated headless test suite passed on clean checkout
- [ ] `export_presets.cfg` updated with target version
- [ ] VRAM texture compression enabled for production export
- [ ] Web headers configured for SharedArrayBuffer / WebGL compatibility
- [ ] Release binaries and checksums generated
- [ ] Rollback binary tag confirmed in registry/releases
```

## Guidelines

- **Reproducible Headless Builds:** Never rely on manual GUI editor exports for official releases; all production builds must be reproducible via CLI.
- **Never Commit Credentials:** Keystores, signing certificates, and export passwords must be injected via environment variables in CI/CD secrets.
- **Web Compatibility:** Ensure GL Compatibility renderer (`renderer/rendering_method="gl_compatibility"`) is set in `project.godot` for broad browser support.
