# Diary Focus

Diary Focus is a cute diary and focus app concept for iOS. It combines a monthly mood calendar, photo diary entries, timestamped life moments, daily todos, and focus sessions with animated companion pets.

This repository currently contains:

- `WebPreview/` - a browser-based product prototype that runs on Windows.
- `DiaryFocusApp/` - an early SwiftUI iOS prototype scaffold.
- `style/` - visual references and background assets used for design exploration.
- `docs/` - product, design, privacy, roadmap, and App Store planning notes.

## Features

- Month calendar with mood icons for past days.
- Mood picker with soft pastel shapes and expressions.
- Diary entries with photos, timestamp moments, and daily todos.
- Focus timer with selectable pet companion and room background.
- Completed focus time appears inside that day's diary.
- Book review search and review library prototype.
- Movie review search prototype.

## Run the Web Preview

On Windows:

```powershell
cd D:\PostPhD\diaryapp
Start-Process .\WebPreview\index.html
```

Or open:

```text
D:\PostPhD\diaryapp\WebPreview\index.html
```

## Run the iOS Prototype

Open this project in Xcode on macOS:

```text
DiaryFocusApp/DiaryFocusApp.xcodeproj
```

The iOS project is a prototype scaffold and is not yet App Store ready.

## Project Status

Current stage: product prototype.

Next target: native iOS MVP with local persistence, photo storage, focus session tracking, settings, and TestFlight readiness.

## Documentation

- [Product Requirements](docs/PRD.md)
- [Roadmap](docs/ROADMAP.md)
- [App Store Checklist](docs/APP_STORE_CHECKLIST.md)
- [Privacy Notes](docs/PRIVACY.md)
- [Design Notes](docs/DESIGN_NOTES.md)
- [Portfolio Case Study Draft](docs/PORTFOLIO_CASE_STUDY.md)

## License

See [LICENSE](LICENSE).
