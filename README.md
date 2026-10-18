# TaskPulse

TaskPulse is a personal task manager built with Flutter. It runs on Android, the web, and desktop, and keeps everything on the device: there is no server or account to set up. Made by Muhammad Mahad.

[![CI](https://github.com/m-m4h4d/mahad-task-manager/actions/workflows/ci.yml/badge.svg)](https://github.com/m-m4h4d/mahad-task-manager/actions/workflows/ci.yml)

## Download

- **Android:** Download `TaskPulse.apk` from the [latest release](https://github.com/m-m4h4d/mahad-task-manager/releases/latest) and install it (you may need to allow installs from unknown sources).
- **Web:** Open [task-pulse-gray.vercel.app](https://task-pulse-gray.vercel.app/) in your browser.

## Features

- **Tasks:** create, edit, delete, and complete tasks. Each task has a title, description, category, priority (low, medium, or high), and comma-separated tags.
- **Search and filter:** search tasks by title and filter by status (all, in progress, or completed).
- **Swipe to delete:** swipe a task away, or use its delete button.
- **Accounts:** sign up and log in with an email and password. Each account sees only its own tasks.
- **Dark mode:** switch between light and dark themes; the choice is remembered.
- **Adaptive layout:** a bottom navigation bar in the mobile and desktop apps; on the web, navigation sits in the app bar, collapsing into a side drawer on narrow windows.
- **Quote of the day:** the profile screen shows a motivational quote from [DummyJSON](https://dummyjson.com/docs/quotes), with a built-in fallback when offline.

Category and priority are saved with each task but are not yet shown in the task list or available as filters.

## How data is stored

| Platform | Tasks | Accounts and settings |
| --- | --- | --- |
| Android, desktop | SQLite (`sqflite`) | `shared_preferences` |
| Web | `shared_preferences` (browser `localStorage`) | `shared_preferences` |

Data never leaves the device, so clearing the app's data (or the browser's site data) deletes it.

> [!IMPORTANT]
> **Accounts are local and for demo purposes only.** Passwords are stored as salted PBKDF2-SHA256 hashes, never in plain text, but accounts live in the same on-device storage as everything else. Anyone with access to the device's storage can read or replace them. Real authentication needs a backend such as Firebase Auth or Supabase.

## Getting started

Requirements: the [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart 3.11.5 or newer.

```bash
git clone https://github.com/m-m4h4d/mahad-task-manager.git
cd mahad-task-manager
flutter pub get

flutter run              # on a connected device or emulator
flutter run -d chrome    # in the browser
```

Other useful commands:

```bash
flutter analyze             # static analysis
flutter test                # tests
flutter build apk --release # Android APK, written to build/app/outputs/flutter-apk/
flutter build web           # web build, written to build/web/
```

### Deploying the web app

The web app is hosted on [Vercel](https://vercel.com/). Vercel's build machines don't include Flutter, so [`vercel.json`](vercel.json) downloads the stable Flutter SDK, runs `flutter build web --release` and serves `build/web`. To set up a new deployment, import the repository into Vercel with the repository root as the project's root directory; the build settings come from `vercel.json`. The landing page in `landing/` is a separate Vercel project whose root directory is `landing`.

### Publishing a release

APKs are not committed to the repository. To publish one, build it with `flutter build apk --release`, rename `app-release.apk` to `TaskPulse.apk` and attach it to a new [GitHub release](https://github.com/m-m4h4d/mahad-task-manager/releases/new). The landing page's download button always points to the `TaskPulse.apk` asset of the latest release, so keep that file name.

## Project structure

```text
lib/
├── main.dart                 # app entry point and routes (go_router)
├── core/
│   ├── database/             # SQLite setup and migrations
│   ├── presentation/         # shared widgets (web footer)
│   ├── theme/                # light/dark themes and theme toggle
│   └── utils/                # shared_preferences access
└── features/
    ├── auth/                 # sign up, log in, session (data / domain / presentation)
    ├── dashboard/            # main screen and adaptive navigation
    ├── profile/              # profile, quote of the day, log out
    └── tasks/                # task model, storage, list and editor
landing/                      # static landing page for the app
```

State management uses [Riverpod](https://riverpod.dev/) and navigation uses [go_router](https://pub.dev/packages/go_router).

## License

TaskPulse is licensed under the [GNU General Public License v3.0](LICENSE).
