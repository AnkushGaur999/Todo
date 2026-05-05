# Flutter Task Manager

A Flutter mobile application that interfaces with
the [JSONPlaceholder API](https://jsonplaceholder.typicode.com) to manage a task list. Demonstrates
BLoC pattern, RESTful API integration, and offline-first architecture with high-performance UI
optimizations.

---

## Features

- ✅ **CRUD Operations**: View, add, complete, and delete tasks.
- 🔍 **Smart Search**: Real-time filtering with debouncing to prevent UI lag.
- 🔄 **Pull-to-Refresh**: Easily sync data with the server manually.
- 📶 **Offline-First**: Full offline support using **Hive** local cache.
- ⚡ **Optimistic UI**: Interface updates instantly while server sync happens in the background.
- 🔁 **Auto-Sync**: Automatically pushes local changes when the internet connection is restored.
- 🔐 **Authentication**: Mock login screen with session persistence (admin/password123).
- 🟠 **Sync Indicators**: Visual cues for items pending upload or deletion.
- 🚀 **Performance Optimized**: Fine-grained rebuilds using `BlocSelector` and segmented Slivers.

---

## Performance Enhancements

To ensure a smooth 60 FPS experience, the following optimizations were implemented:

1. **Event Debouncing**: Using `stream_transform`, the search functionality is debounced by 300ms.
   This prevents the BLoC from re-filtering the list on every single keystroke, significantly
   reducing CPU usage.
2. **Fine-Grained Rebuilds**: Replaced global `BlocBuilder` with specific `BlocSelector`s in the
   list screen. This ensures that only the affected part of the UI (e.g., just the progress bar or
   just the sync banner) rebuilds when specific state fields change.
3. **Widget Segmentation**: The `TodoListScreen` is broken down into small, specialized Sliver
   widgets (`_TodoHeaderSliver`, `_TodoListSliver`, etc.). This localizes rebuilds and improves
   scroll performance.
4. **Optimistic State Management**: The repository provides immediate feedback to the UI, while the
   BLoC handles the reconciliation with the server asynchronously.

---

## Setup Instructions

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / Xcode for device emulation

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/AnkushGaur999/Todo.git
cd todo_app

# 2. Install dependencies
flutter pub get

# 3. The Hive adapter is pre-generated (todo_model.g.dart).
#    If you modify TodoModel, regenerate it with:
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Demo Credentials

| Field    | Value         |
|----------|---------------|
| Username | `admin`       |
| Password | `password123` |

---

## Project Structure

```
lib/
├── main.dart                         # Entry point & Dependency Injection init
├── app.dart                          # Root widget + Theme & Bloc Providers
├── core/
│   |── di/
│   |   └── injection.dart            # GetIt service locator configuration
|   |── network/
│   |   |── interceptors/
│   |   |   |──auth_interceptor.dart    # Auth Interceptor for authorization
│   |   |   |──retry_interceptor.dart   # Retry Interceptor for retry request
│   |   └── api_client.dart             # Api client for make requests(GET, POST, PUT, PATCH, DELETE)
├── data/
│   ├── models/
│   │   ├── todo_model.dart           # Hive-annotated model with sync logic
│   │   └── todo_model.g.dart         # Generated Hive adapter
│   ├── datasources/
│   │   ├── local/
│   │   │   └── todo_local_datasource.dart   # Hive CRUD operations
│   │   └── remote/
│   │       └── todo_remote_datasource.dart  # Dio HTTP client implementation
│   └── repositories/
│       └── todo_repository_impl.dart # Orchestrates local cache vs remote API
└── presentation/
    ├── bloc/
    │   ├── auth/
    │   │   └── auth_bloc.dart         # Login / logout state management
    │   └── todo/
    │       ├── todo_bloc.dart         # Core logic + connectivity stream + debouncing
    │       ├── todo_events.dart
    │       └── todo_states.dart
    ├── screens/
    │   ├── login_screen.dart
    │   └── todo_list_screen.dart      # Performance-optimized Sliver-based list
    └── widgets/
        ├── todo_tile.dart             # Swipe-to-delete list item with sync icons
        ├── add_todo_dialog.dart       # Bottom sheet for new tasks
        └── connectivity_banner.dart  # Animated Online/Offline status bar
```

---

## BLoC Pattern Explanation

```
UI (Widget)
    │  dispatches Events
    ▼
TodoBloc
    │  calls Repository methods
    ▼
TodoRepository
    ├── TodoRemoteDataSource  (Dio → JSONPlaceholder API)
    └── TodoLocalDataSource   (Hive → device storage)
    │
    └── emits States back to UI via BlocSelector/BlocBuilder
```

---

## Offline Support Strategy

1. **Write-Through Cache**: When online, data is written to the API and then mirrored to Hive.
2. **Pending Actions**: If offline, the item is saved to Hive with a `pendingAction` flag (`create`,
   `update`, or `delete`).
3. **Optimistic UI**: The `TodoBloc` emits the updated local list immediately so the user sees no
   lag.
4. **Sync Engine**:
    * Listens to `connectivity_plus` stream.
    * When connection returns, it iterates through all Hive items with `pendingAction != 'none'`.
    * Executes the corresponding API calls sequentially.
    * Updates the local item with the server's `id` and resets the flag.

---

## Challenges & Solutions

| Challenge              | Solution                                                                                                                                          |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| **Optimistic IDs**     | Used UUIDs as `localId` keys for Hive, swapping them for server `id`s after successful sync.                                                      |
| **Duplicate Syncs**    | Used `.distinct()` on the connectivity stream to ignore redundant network state changes.                                                          |
| **Search Performance** | Implemented `EventTransformer` with `debounce` in `TodoBloc` to limit filtering frequency.                                                        |
| **UI Over-rebuilding** | Segmented the main screen into smaller components using `BlocSelector` for localized updates.                                                     |
| **API Limitations**    | JSONPlaceholder is a mock API and doesn't persist data; handled this by relying on our local Hive cache as the "source of truth" for the session. |

---

## API Endpoints Used

| Method   | Endpoint           | Purpose           |
|----------|--------------------|-------------------|
| `GET`    | `/todos?_limit=20` | Load initial list |
| `POST`   | `/todos`           | Create new todo   |
| `PATCH`  | `/todos/:id`       | Toggle completed  |
| `DELETE` | `/todos/:id`       | Delete a todo     |
