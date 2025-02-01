# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-02-01

### Added

- Full SDL3 support (3.2.0 or later)
- SDL3_ttf support
- SDL3_mixer support
- Comprehensive test suite
- Modern error handling using bool returns instead of error codes
- Floating-point coordinates for rendering
- New event system with SDL3 prefixes

### Changed

- BREAKING: Updated to SDL3's new API
- BREAKING: Function return values now use bool for success/failure
- BREAKING: Version information now uses packed integer format
- BREAKING: Hint system now returns bool for success/failure
- BREAKING: Window and renderer creation updated for SDL3
- BREAKING: Event types now use SDL_EVENT_ prefix
- Improved frame timing system
- Enhanced error handling and testing
- Updated documentation for SDL3

### Removed

- BREAKING: Removed SDL2 support
- BREAKING: Removed deprecated SDL2 functions and types
- BREAKING: Removed old event type names

## [1.1.7] - Previous Release

For changes prior to 2.0.0, please refer to the git history.
