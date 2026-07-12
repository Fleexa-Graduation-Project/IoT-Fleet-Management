<div align="center">
  <img src="../docs/assets/fleexa_letter_logo.svg" alt="Logo" width="120" height="120">
  <br></br>
  <h1>Fleexa Mobile Client</h1>
  <p><strong>The official cross-platform mobile command center for the Fleexa IoT Fleet Management ecosystem.</strong></p>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28.svg?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com/)
</div>

---

## Overview

The **Fleexa Mobile App** is the centralized command center for the virtual IoT ecosystem. Built entirely with Flutter, it empowers users to monitor real-time environmental metrics, execute remote actuator commands, and receive critical push notifications safely without relying on any physical hardware. The application is built to handle high-frequency IoT data streams flawlessly while maintaining a smooth 60 FPS performance.

---

## Deep Dive: Directory Architecture

The mobile project enforces a strict, domain-driven architecture within the `lib/` directory, ensuring optimal scalability, separation of concerns, and testability:

```text
mobile/lib/
├── core/                        # Global configurations, services, and shared utilities
│   ├── cubits/                  # Global state management (e.g., LocalizationCubit)
│   ├── errors/                  # Centralized error handling and exception mapping
│   ├── network/                 # Dio API service definitions and constants
│   ├── router/                  # Centralized navigation using AppRouter
│   ├── services/                # External service integrations (e.g., PushNotificationService)
│   ├── setup/                   # Dependency injection (Service Locator) and App Initializers
│   ├── storage/                 # Secure token storage for JWTs
│   ├── utils/                   # Design system constraints
│   └── widgets/                 # Reusable Global UI components
├── features/                    # Isolated, feature-based modules
│   ├── auth/                    # User registration, login, and password recovery
│   ├── devices/                 # IoT specific modules mapped to physical counterparts
│   │   ├── actuators/           # AC Control and Smart Door Locks
│   │   ├── sensors/             # Gas, Light, and Temperature sensors
│   │   └── shared/              # Shared models and cubits
│   ├── on_boarding/             # Initial user walkthrough and platform introduction
│   ├── overview/                # Multi-device dashboards, telemetry insights, and notification centers
│   ├── settings/                # Profile management, and support
│   └── splash/                  # Application initialization screen
└── main.dart                    # Application entry point
```

---

## Core Frontend Mechanisms

To guarantee a premium user experience while interacting with cloud-based virtual hardware, the application implements several advanced frontend techniques:

*   **Smart Screen Updates (Reactive State):** Utilizes `Cubit` and `BlocBuilder` to rebuild only the specific widgets that require updates (e.g., a single temperature gauge) rather than redrawing the entire screen. 
*   **The "Zero-Delay" Illusion (Optimistic UI):** When dispatching remote commands to actuators (like unlocking a smart door), the UI instantly reflects the new target state while the command processes securely in the background. Upon cloud confirmation, the app synchronizes quietly to maintain a frictionless feel.
*   **Emergency Background Alerts:** A dedicated Firebase Cloud Messaging (FCM) listener runs continuously, ensuring that urgent warnings (e.g., gas leak thresholds exceeded) trigger push notifications instantly, even if the application is closed.
*   **Seamless Transitions & Placeholders:** Instead of standard spinners, the app employs `Skelton` loading effects during historical data fetches to provide visual placeholders, significantly reducing perceived latency.
*   **Interactive Data Visualization:** Integrates Syncfusion Flutter Gauges and Charts to translate heavy, raw telemetry records into clean, interactive historical trend charts.

---

## Technical Stack

*   **Framework:** Flutter & Dart.
*   **State Management:** `flutter_bloc`.
*   **Network Requests:** `dio`.
*   **Routing:** `go_router` via `AppRouter`.
*   **Dependency Injection:** `get_it` via `ServiceLocator`.
*   **Data Visualization:** `syncfusion_flutter_charts`, `syncfusion_flutter_sliders`, `syncfusion_flutter_gauges`.
*   **Push Notifications:** `firebase_messaging`.

---

## Getting Started

Follow these instructions to get the Fleexa Mobile Client up and running on your local device.

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
*   **Android Studio** or **VS Code** (with Flutter/Dart plugins).
*   A physical device or emulator.

### 1. Installation

Clone the repository and navigate to the mobile directory:
```bash
cd IoT-Fleet-Management/mobile
```

Install the required dependencies:
```bash
flutter pub get
```

### 2. Run the App

Connect your device and launch the application:
```bash
flutter run
```

*Once the app is running, you can create a new account directly through the sign-up screen and start interacting with the virtual device fleet immediately.*

---

## Security Highlights

*   **Secure Authentication** Integrated with AWS Cognito for managed user identity and secure sign-in flows.
*   **Token Isolation** JWT tokens are securely encapsulated using `flutter_secure_storage` and automatically injected into request headers.
*   **Encrypted Traffic** All API communications are strictly enforced over HTTPS.