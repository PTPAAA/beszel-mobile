# Beszel Mobile

> **A beautiful, real-time mobile companion for your [Beszel](https://github.com/henrygd/beszel) server monitoring hub.**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![PocketBase](https://img.shields.io/badge/PocketBase-%23B8DBE4.svg?style=for-the-badge&logo=PocketBase&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

Beszel Mobile brings your server metrics to your pocket. Connect to your existing Beszel instance to monitor CPU, RAM, Disk, and Network usage in real-time, receive local alerts for downtime, and view historical data with beautiful, interactive charts.

---

## What's New
- **🔐 PIN Security**: Secure your app with a 4-digit PIN code. Supports Setup, Verification, and automatic cleanup on logout.
- **🔄 Custom Pull-to-Refresh**: Smooth, animated dashboard refreshing with a custom spinning icon.
- **⚡ Enhanced Alerts**: 
    - **Uniform 80% Threshold**: Immediate alerts if CPU, RAM, or Disk usage exceeds 80%.
    - **Startup Checks**: Instantly checks system health upon app launch—no more waiting for changes to trigger alerts.
    - **Safe-Start**: Optimized initialization ensures the app launches instantly, even with heavy data loads.

---

## Features

### 📊 Real-Time Dashboard
- Live updates of all your connected systems.
- **Status Indicators**: Instant visual feedback on system health (Green/Red).
- **Sorting**: Sort systems by Name, CPU, RAM, or Disk usage.
- **Pull-to-Refresh**: Manually refresh data with a fluid, custom animation.

### 📈 Detailed Analytics
- **Interactive Charts**: History for **CPU**, **Memory**, **Disk**, and **Network Traffic**.
- **Precision Data**: Touch anywhere on the chart for exact metrics.
- **Dynamic Scaling**: Charts adapt automatically to your data range.

### 🔔 Smart Alerts System
- **Immediate Notifications**: Get notified instantly on your device if:
    - A server goes **DOWN**.
    - **CPU**, **RAM**, or **Disk** usage exceeds **80%**.
- **Startup Protection**: Detects overloaded servers immediately when you open the app.
- **Alert History**: Persistent log of all past critical events (capped for performance).

### 🌍 Localization & Customization
- **Multi-language**: Fully localized in **English** 🇺🇸 and **Russian** 🇷🇺.
- **Theme Support**: Beautiful **Dark** and **Light** modes.
- **User Profiles**: View your account details with a dedicated User Info screen.

---

## Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.
- A running instance of **[Beszel](https://github.com/henrygd/beszel)** (the backend).

### Steps
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/beszel-mobile.git
    cd beszel-mobile
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    # For Android
    flutter run -d android
    ```

---

## Configuration

1.  **Open the App**: You will be greeted by the Setup Screen.
2.  **Enter Server URL**: Input the full URL of your Beszel instance (e.g., `https://beszel.yourdomain.com`).
3.  **Login**: Use your existing Beszel credentials.
4.  **Set PIN (Optional)**: Secure your session with a PIN code in the User Menu.

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend SDK**: `pocketbase` (Dart client)
- **Charts**: `fl_chart`
- **State Management**: `provider`
- **Localization**: `easy_localization`
- **Notifications**: `flutter_local_notifications`
- **Styling**: Custom `custom_refresh_indicator`
- **Storage**: `shared_preferences`

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request
