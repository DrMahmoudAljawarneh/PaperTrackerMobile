# Paper Tracker

Paper Tracker is a cross-platform Flutter application designed to help researchers, students, and academics manage their academic papers, collaborate on tasks, track progress, and communicate in real-time.

## Features

- **Authentication & User Profiles:** Secure email/password login using Firebase Authentication.
- **Paper Management:** Add, edit, and track the status of academic papers (Idea, Drafting, Review, Submitted, Published, etc.).
- **Task Tracking:** Assign and track tasks related to specific papers.
- **Real-time Comments:** Leave comments on papers for collaborators to see.
- **Collaborator Management:** Assign multiple authors/collaborators to papers so everyone stays in sync.
- **Real-time User Chat:** Built-in direct messaging system between users, powered by Firebase Realtime Database.
- **Cross-Platform:** Supports Android, iOS, and Web.

## Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [BLoC Pattern](https://bloclibrary.dev/) (flutter_bloc)
- **Backend & Database:** [Firebase Realtime Database](https://firebase.google.com/products/realtime-database)
- **Authentication:** [Firebase Authentication](https://firebase.google.com/products/auth)
- **Routing:** [GoRouter](https://pub.dev/packages/go_router)
- **UI Design:** Custom dark-themed Glassmorphism aesthetic using Material 3.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.7 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- A Firebase project with Authentication (Email/Password) and Realtime Database enabled.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DrMahmoudAljawarneh/PaperTrackerMobile.git
   cd PaperTrackerMobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. **(Optional)** If you need to reconfigure Firebase for your own backend, run the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

4. Run the app:
   ```bash
   # Run on an Android emulator or connected device
   flutter run
   
   # Run on the web Browser (Chrome)
   flutter run -d chrome
   ```

## Web Compatibility

The application is fully configured to run on the web. It conditionally initializes native-only packages (like `flutter_downloader`) to ensure smooth execution in browsers, and includes all necessary Firebase web dependencies.

## Generating Icons

If you wish to update the app branding, replace `assets/icon.png` with your new 1024x1024 image and run:
   ```bash
   dart run flutter_launcher_icons
   ```
