# GatherHype — Flutter

A Flutter port of the GatherHype Angular app. Save, organize, and share links with folder trees, multi-language support, and AI summaries.

## Features

- 🔐 **Auth** — Login, Register, Forgot/Reset password (JWT)
- 📁 **Folders** — Create, delete, move, share folders with nested subfolders
- 🔗 **Links** — Save URLs with auto-translated titles & descriptions
- 🌍 **Languages** — Per-link language switcher, global language selector
- 🔍 **Search** — Global search across folders and links
- 🤖 **AI Summary** — Generate AI summaries of folder contents
- 📤 **Sharing** — Share folders with other users by email
- 📱 **Responsive** — Sidebar layout on tablet/desktop, drawer on mobile

## Getting Started

```bash
flutter pub get
flutter run
```

## API

Connects to `https://api.gatherhype.com/api` by default.  
Change in `lib/core/utils/app_config.dart`.

## Project Structure

```
lib/
├── main.dart                        # Entry point + auth gate
├── core/
│   ├── models/
│   │   ├── folder_model.dart        # Folder, FolderTree, SharedUser
│   │   └── link_model.dart          # Link, CreateLinkRequest
│   ├── services/
│   │   ├── api_client.dart          # HTTP client with JWT auth header
│   │   ├── auth_service.dart        # Login, register, logout, token
│   │   ├── folders_service.dart     # Folders CRUD + share + move + summary
│   │   ├── links_service.dart       # Links CRUD + move + override
│   │   └── user_service.dart        # Translation settings
│   └── utils/
│       ├── app_config.dart          # API URL + storage keys
│       └── app_theme.dart           # Material 3 light/dark theme
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart  # + ResetPasswordScreen
│   └── hub/
│       └── hub_screen.dart          # Main app shell
└── shared/
    ├── dialogs/
    │   └── dialogs.dart             # AddFolder, AddLink, Delete, Share, AISummary
    └── widgets/
        ├── folder_sidebar.dart      # Folder list with context menu
        ├── link_grid.dart           # Link cards grid with lang switching
        ├── move_folder_dialog.dart  # Move folder tree picker
        └── search_bar.dart          # Global search with dropdown results
```
