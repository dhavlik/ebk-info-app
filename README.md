# ebk info

> [!NOTE]
> **🤖 AI-Generated Repository**: This repository contains approximately **99% LLM-generated content**. The code, documentation, and project structure were created through AI-assisted development using GitHub Copilot, with minimal human intervention for complex logic fixes and requirements specification.

[![CI/CD Pipeline](https://github.com/dhavlik/ebk-info-app/actions/workflows/ci.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/ci.yml)
[![Pull Request Checks](https://github.com/dhavlik/ebk-info-app/actions/workflows/pr.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/pr.yml)
[![Release](https://github.com/dhavlik/ebk-info-app/actions/workflows/release.yml/badge.svg)](https://github.com/dhavlik/ebk-info-app/actions/workflows/release.yml)

A Flutter mobile and web application for the **Eigenbaukombinat (EBK)** hackerspace in Halle (Saale), Germany. 

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

### 📚 Documentation Browser
- **Integrated wiki access** - Browse EBK documentation directly in the app
- **Streamlined navigation** - Simple two-level structure (categories → pages)
- **External browser integration** - Documentation opens in your default browser for full functionality
- **Organized content** - Easy access to how-tos, guides, and EBK information
‚
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

### Documentation Integration
- **`https://wiki.eigenbaukombinat.de/`** - EBK Wiki/Documentation
  - Integrated documentation browser for accessing guides and how-tos
  - Parses wiki structure to provide streamlined navigation
  - Opens content in external browser for full wiki functionality

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
- **Complex Code Fixes**: Manually resolved intricate logic issues when AI solutions became inefficient or overly complicated, leveraging human intelligence for nuanced problem-solving

### The Result

This project produced a fully functional Flutter application with real-time features, comprehensive internationalization, and extensive testing - successfully demonstrating the potential of AI-assisted development. However, the development process also revealed significant limitations in current AI capabilities.

**The AI excelled at** structured tasks like file creation, API integration, and UI implementation, but **struggled with efficiency when problems became even moderately complex**. Intricate logic flows, cross-service state management, and nuanced debugging scenarios often led to overcomplicated AI solutions that required human intervention to simplify and optimize.

This collaborative approach represents an experimental model for human-AI programming partnerships, clearly illustrating both the remarkable potential and current boundaries of AI-assisted software development.

## Development information

### 🛠️ Setup Development Environment

**Prerequisites:**
- **Flutter SDK** - Install from [flutter.dev](https://docs.flutter.dev/get-started/install)
- **Android SDK** - Required for Android builds (via Android Studio or command line tools)
- **Git** - Version control and pre-commit hooks

**Essential Commands:**
```bash
# Check code quality and lint issues
flutter analyze

# Run all tests (unit + E2E)
flutter test

# Build for web/Android
flutter build web
flutter build apk
```

**Pre-commit Setup:**
```bash
# Install pre-commit hooks for code quality
./scripts/setup-precommit.sh
```

### 🏷️ Creating Releases

To create a new release:

```bash
# Tag a new version
git tag v1.0.0
git push origin v1.0.0
```
