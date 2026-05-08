# MCOOL

A Flutter-based repair billing assistant for local invoice generation, client management, and printable PDF bills.

## Overview

`MCOOL` is a cross-platform Flutter app built for desktop and mobile that helps repair shops manage clients, record invoices, and generate professional billing documents. It uses local storage, reactive state management, and PDF generation to keep the workflow fast and offline-ready.

## Architecture

The application follows a clean, modular structure:

- `lib/main.dart` - app entrypoint and global `ProviderScope` setup.
- `lib/src/screens/` - UI screens for dashboard, history, clients, invoice creation, and invoice preview.
- `lib/src/provider/` - Riverpod providers for clients, invoices, and PDF generation.
- `lib/src/database/` - SQLite storage logic using `sqflite` and `path`.
- `lib/src/models/` - data models for clients, invoices, and invoice line items.
- `lib/src/components/` - reusable UI components and widgets.
- `lib/src/utils/` - shared utility helpers.

## Key Features

- Dashboard overview with recent invoices and quick access to main app sections.
- Invoice history with full list of past invoices.
- Client management and search, including quick selection of existing clients.
- New invoice creation with dynamic line items and automatic total calculation.
- Local persistence with SQLite database for clients, invoices, and invoice items.
- PDF invoice generation and printing via `pdf` and `printing` packages.
- Riverpod state management for reactive UI updates and clean data flow.

## Dependencies

The project uses these main packages:

- `flutter_riverpod` - state management
- `sqflite` - local SQLite database
- `path` - file path utilities for database storage
- `pdf` - PDF document generation
- `printing` - preview and print PDF documents
- `cupertino_icons` - iOS-style icons

## Project Structure

- `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/` - platform-specific Flutter configurations.
- `lib/main.dart` - starts the app and configures theme + home screen.
- `lib/src/screens/` - screen-level UI logic.
- `lib/src/provider/` - state providers and business logic bridges.
- `lib/src/database/database_helper.dart` - schema creation and DB operations.
- `lib/src/models/` - typed data classes.

## Getting Started

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Open this repository in your editor.
3. Run dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

5. To build for a specific platform:

```bash
flutter build apk
flutter build ios
flutter build windows
flutter build macos
flutter build linux
```

## Notes

- The app stores data locally in `repair_billing.db` using SQLite.
- Clients and invoices are retained between app launches.
- PDFs are built dynamically and can be printed or previewed.
- The app currently uses a single `ProviderScope` and Riverpod providers for data refresh and invalidation.

## License

This repository does not specify a license. Add a license file if you want to publish or share the project publicly.
