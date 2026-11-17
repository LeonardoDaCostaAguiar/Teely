# Teely

[![iOS CI](https://github.com/LeonardoDaCostaAguiar/Teely/actions/workflows/ios-ci.yml/badge.svg?branch=main)](https://github.com/LeonardoDaCostaAguiar/Teely/actions/workflows/ios-ci.yml)

Teely is an iOS app for discovering movies and series and keeping track of what you watch. It retrieves data from the [TMDB API](https://www.themoviedb.org/documentation/api) and presents it in a SwiftUI neumorphic interface with light and dark modes.

## Features

- Discover weekly trending movies and TV shows on the Home tab
- Search movies and series by title from the Home tab, in the device language
- View movie and series details including release dates, credits, production data, cast, and official trailers that play inside the app when TMDB provides them
- Save titles to your library with "Save to my Library"
- Mark a saved title as "Watched" or "Want to watch"
- Rate a watched title with "Liked" or "Disliked"
- Filter the Library tab by "All", "Watched", or "Want to watch"
- See saved titles on the Library tab, in a centered grid of cards, in cards sized like the Home posters, each showing the cover, the full title, the type, and the status
- Support for English, Brazilian Portuguese, and Spanish
- Use the app in light or dark mode

## Requirements

- iOS 17.0 or later

## Architecture

The app follows the VIP (View–Interactor–Presenter) architecture, with screens for Home, Library, Search, and Detail.
Each scene defines its Request, Response, and ViewModel types, so every layer can be tested in isolation.

## Testing

- Unit tests (XCTest)
- UI tests (XCUITest)

## Built With

- Swift
- SwiftUI
- SwiftData
- VIP architecture
- [TMDB API](https://www.themoviedb.org/documentation/api)
- XCTest and XCUITest
- GitHub Actions
- Neumorphic visual design

## Author

Created by **Leonardo da Costa Aguiar**.
