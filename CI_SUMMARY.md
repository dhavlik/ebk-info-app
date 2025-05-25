
# 🔄 CI/CD Pipeline Summary

## 📋 AKTUELLE WORKFLOWS (Stand: 25. Mai 2025)

Basierend auf den vorhandenen Workflow-Dateien in `.github/workflows/`:

### ✅ **Aktive Workflows:**

#### 1. 🚀 **CI Pipeline** (`ci.yml`)
- **Trigger:** Push auf `main` und `develop` branches
- **Job:** `test` (ubuntu-latest)
- **Features:**
  - ✅ Java 17 (Zulu Distribution) Setup
  - ✅ Flutter 3.32.0 (stable channel) mit Cache
  - ✅ Intelligente Dart-Formatierung:
    - Auto-Commit auf main branch mit `[skip ci]`
    - PR-Erstellung bei Branch Protection
    - Fallback zu PR wenn direkter Commit fehlschlägt
  - ✅ Flutter Analyze (Code-Qualität)
  - ✅ Tests mit Integration-Test-Ausschluss:
    - `--exclude-tags=integration`
    - `--dart-define=FLUTTER_TEST_INTEGRATION_DISABLED=true`
    - `--coverage` aktiviert
- **Permissions:** `contents: write`, `actions: read`, `checks: write`

#### 2. 🔍 **PR Pipeline** (`pr.yml`) 
- **Trigger:** Pull Requests zu `main`
- **Jobs:** 
  - `test` (ubuntu-latest) - Identisch zu ci.yml
  - `build-android` (ubuntu-latest) - APK Build mit Artifact Upload
  - `build-web` (ubuntu-latest) - Web Build mit Artifact Upload
- **Features:**
  - ✅ Vollständige Test- und Analyse-Pipeline
  - ✅ Android APK Build (30 Tage Retention)
  - ✅ Web Build mit korrekter Base-Href (`/ebk-info-app/`)
  - ✅ Artifact-Upload für beide Plattformen
- **Dependencies:** build-jobs benötigen erfolgreiche Tests

#### 3. 🎁 **Release Pipeline** (`release.yml`)
- **Trigger:** Git Tags (`v*.*.*`) + Manual Dispatch
- **Jobs:**
  - `create-release` - GitHub Release erstellen
  - `build-android` - APK Build und Upload
  - `build-web` - Web Build und Upload
  - `deploy-web` - GitHub Pages Deployment (nur main branch)
- **Features:**
  - ✅ **Moderne GitHub CLI** (`gh release create/upload`)
  - ✅ Automatische Release-Erstellung mit Notizen
  - ✅ Android APK Upload zum Release
  - ✅ Web Build als TAR.GZ Archive
  - ✅ GitHub Pages Deployment mit korrekten Permissions
- **Permissions:** `contents: write`, `actions: read` (plus Pages-spezifische)

### 🚫 **Deaktivierte Features:**

#### Integration Tests:
- **Status:** Temporär deaktiviert in allen Workflows
- **Betroffene Dateien:** 4 `.disabled` Test-Dateien
- **Exclusion-Flags:** `--exclude-tags=integration --dart-define=FLUTTER_TEST_INTEGRATION_DISABLED=true`
- **Grund:** Flutter 3.32.0 Kompatibilitätsprobleme (MissingPluginException)

#### iOS Support:
- **Status:** Nicht vorhanden in keinem Workflow
- **Grund:** Noch nicht unterstützt, keine macOS Runner

### 🔧 **Workflow-Details:**

#### Auto-Formatierung (ci.yml + pr.yml):
```bash
# Intelligente Formatierungslogik:
dart format .
# Bei main branch + push event → Auto-Commit
# Bei anderen Situationen → PR-Erstellung
# Fallback bei Branch Protection → PR mit automated-formatting-* branch
```

#### Web Build Konfiguration:
```bash
flutter build web --release --base-href="/ebk-info-app/"
```

#### Release-Assets:
```bash
# Android APK: build/app/outputs/flutter-apk/app-release.apk
# Web Archive: build/web-build.tar.gz
```

### 📊 **Aktueller Zustand:**
- ✅ **3 aktive Workflows** (ci.yml, pr.yml, release.yml)
- ✅ **Flutter 3.32.0** auf allen Pipelines
- ✅ **Java 17** für Android Builds
- ✅ **Coverage Reports** in Tests aktiviert
- ✅ **Artifact Management** mit 30-Tage Retention
- ✅ **GitHub Pages** Deployment funktional

### 🎯 **Deployment-Targets:**
- ✅ **Android APK:** Release-Upload + PR-Artifacts
- ✅ **Web (GitHub Pages):** Automatisches Deployment bei Releases
- ❌ **iOS:** Nicht verfügbar

