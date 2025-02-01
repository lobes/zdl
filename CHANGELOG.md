# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.7] - 2025-02-01

### Added

- Functionally-full SDL3 support (3.2.0 or later): did not reimplement anything already in Zig stdLib
- SDL3_ttf support
- SDL3_mixer support
- Comprehensive test suite
- Modern error handling using bool returns instead of error codes
- Floating-point coordinates for rendering
- New event system with SDL3 prefixes

### Changed

- Updated to SDL3's new API
- Function return values now use bool for success/failure
- Version information now uses packed integer format
- Hint system now returns bool for success/failure
- Window and renderer creation updated for SDL3
- Event types now use SDL_EVENT_ prefix
- Improved frame timing system
- Enhanced error handling and testing
- Updated documentation for SDL3

### Removed

- Nothing. First Release
