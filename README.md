# ebk info

[![CI/CD Pipeline](https://github.com/dhavlik/ebk-info-app/actions/workflows/ci.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/ci.yml)
[![Pull Request Checks](https://github.com/dhavlik/ebk-info-app/actions/workflows/pr.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/pr.yml)
[![Release](https://github.com/dhavlik/ebk-info-app/actions/workflows/release.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/release.yml)

A Flutter mobile and web application for the **Eigenbaukombinat (EBK)** hackerspace in Salzwedel, Germany. 

## What the App Does

**ebk info** provides real-time information and convenient access to essential EBK services:

### 🔴🟢 Live Space Status
- **Real-time open/closed status** of the hackerspace
- **"Open until" notifications** showing when the space will close
- **Automatic updates** every 5 minutes, even when the app runs in the background
- **Push notifications** when the space status changes

### 📅 Event Listings
- **Live event feed** from the official EBK calendar
- **Next 5 upcoming events** with option to show all
- **Smart event display** with proper handling of all-day events
- **Calendar integration** - download events directly to your calendar via iCal
- **Today highlighting** - events happening today are clearly marked
- **Localized date/time formatting** for German and English users

### 🔗 Important Links & Contact
- **Quick access** to the official EBK website
- **Direct contact options** - phone and email with one-tap functionality
- **Location integration** - view EBK's location on OpenStreetMap
- **Social media links** for staying connected

### 🌐 Full Internationalization
- **Bilingual support** - German and English
- **Automatic language detection** based on device settings
- **Localized date/time formats** respecting regional preferences

### 🌙 Dark Mode Support
- **Automatic theme switching** based on system preferences
- **Carefully designed** light and dark themes for optimal readability
- **Consistent branding** with EBK logo integration

The app serves as a **comprehensive companion** for EBK members and visitors, keeping them informed about space availability, upcoming events, and providing easy access to essential contact information.

## Technical Overview

### Architecture
The app follows a **clean architecture pattern** with clear separation of concerns:

- **Models** - Data structures for events, space status, and configuration
- **Services** - Business logic and API communication layer
- **Widgets** - Reusable UI components with single responsibilities  
- **Screens** - Top-level pages that compose widgets and manage state

### Framework & Platform
- **Flutter 3.24.3** - Cross-platform framework for mobile and web
- **Dart** - Programming language with null safety
- **Web Support** - Runs natively in browsers via Flutter Web
- **Android Support** - Native Android APK compilation

### Key Dependencies
- **HTTP Client** - RESTful API communication
- **URL Launcher** - External link and contact integration
- **Flutter Localizations** - Internationalization (i18n) support
- **Local Notifications** - Background status change alerts
- **Intl** - Date/time formatting and localization

### State Management
- **StatefulWidget** - Local component state management
- **Provider Pattern** - Service-based dependency injection
- **Background Timers** - Automatic polling without external state libraries

## API Endpoints

The app integrates with existing EBK services through these endpoints:

### SpaceAPI Integration
- **`https://spaceapi.eigenbaukombinat.de/`** - Main SpaceAPI endpoint
  - Provides real-time hackerspace status (open/closed)
  - Returns space information, contact details, and current state
  - Follows the standard SpaceAPI specification

- **`https://spaceapi.eigenbaukombinat.de/openuntil.json`** - Opening hours endpoint
  - Returns "open until" timestamp when the space is currently open
  - Used for displaying countdown timers and closing notifications

### Event Calendar
- **`https://kalender.eigenbaukombinat.de/json/`** - EBK Calendar API
  - Provides upcoming events in JSON format
  - Returns event details including title, description, date/time, and URLs
  - Supports both regular timed events and all-day events

## How This Code Was Actually Made

### The Honest Truth
This entire Flutter application was **created through AI-assisted development** using GitHub Copilot as the primary coding assistant. The development process was a collaborative conversation between a human developer and an AI, with the AI doing the actual code writing, file creation, and implementation.

### Development Process
- **Initial Requirements**: Human provided high-level requirements for an EBK hackerspace app
- **Iterative Development**: AI suggested architecture, created files, and implemented features step by step
- **Real-time Feedback**: Human tested the app in browser and provided feedback for improvements
- **Continuous Refinement**: AI made adjustments based on testing results and user preferences

### What the AI Did
- **Complete Project Structure**: Created all Flutter files, folders, and configurations from scratch
- **API Integration**: Implemented SpaceAPI and calendar API connectivity with proper error handling
- **UI/UX Design**: Built responsive widgets, theme support, and user interface components
- **Internationalization**: Set up complete German/English localization with ARB files
- **Testing**: Created comprehensive end-to-end tests with mocked API responses
- **Build Configuration**: Set up Android and web builds with proper manifests and icons

### What the Human Did
- **Requirements Definition**: Specified features, endpoints, and desired functionality
- **Quality Assurance**: Tested the app in browser and provided feedback on user experience
- **Design Decisions**: Made choices about colors, layout adjustments, and feature priorities
- **Real-world Validation**: Ensured integration with actual EBK services and APIs

### The Result

A functional Flutter application that successfully demonstrates AI-assisted development capabilities. While the app includes real-time features, internationalization, and testing, it represents an experimental approach to collaborative human-AI programming rather than a traditional development process.

## 🚀 CI/CD Pipeline

This project includes a comprehensive GitHub Actions pipeline for automated testing, building, and deployment:

### 🔄 Automated Workflows

**Main CI/CD Pipeline** (`.github/workflows/ci.yml`)
- **Testing**: Automated test suite with coverage reporting
- **Code Quality**: Dart formatting and static analysis checks
- **Multi-Platform Builds**: Android APK, iOS app, and Web builds
- **Security Scanning**: Dependency vulnerability checks
- **GitHub Pages**: Automatic web deployment on main branch

**Pull Request Validation** (`.github/workflows/pr.yml`)
- Quick formatting and analysis checks
- Basic build verification
- Prevents broken code from entering main branch

**Release Automation** (`.github/workflows/release.yml`)
- Triggered by version tags (e.g., `v1.0.0`)
- Builds production APK and App Bundle for Android
- Creates iOS build archive
- Uploads release assets automatically
- Generates release notes

**Nightly Builds** (`.github/workflows/nightly.yml`)
- Runs comprehensive tests every night
- Checks for dependency updates
- Early detection of integration issues

### 🤖 Dependency Management

**Dependabot** (`.github/dependabot.yml`)
- Automatically updates Flutter/Dart dependencies weekly
- Updates GitHub Actions to latest versions
- Creates pull requests for security updates

### 📋 Issue & PR Templates

**Bug Reports** - Structured template with:
- Platform and version information
- Steps to reproduce
- Device details and logs

**Feature Requests** - Template including:
- Problem description
- Proposed solution
- Priority and platform targeting

**Pull Request Template** - Checklist for:
- Code quality verification
- Testing requirements
- Platform compatibility

### 🛡️ Security

- **Security Policy** (`SECURITY.md`) with vulnerability reporting process
- Automated security scanning in CI pipeline
- Dependency vulnerability monitoring

### 🏷️ Creating Releases

To create a new release:

```bash
# Tag a new version
git tag v1.0.0
git push origin v1.0.0
```

This automatically:
1. Triggers the release workflow
2. Builds Android APK and App Bundle
3. Creates iOS build archive  
4. Uploads assets to GitHub release
5. Generates release notes

### 📊 Build Status

Current build status can be monitored via the badges at the top of this README. All workflows include:

- ✅ **Automated testing** with Flutter test suite
- ✅ **Code quality checks** with dart analyze
- ✅ **Multi-platform builds** (Android, iOS, Web)
- ✅ **Security scanning** for vulnerabilities
- ✅ **Dependency monitoring** with Dependabot