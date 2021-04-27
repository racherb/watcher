# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2.1] - 2021-04-23

### Added

- Create watcher function
- Run watcher function
- Wait for watcher function
- Atomic functions over watchables
- Folder recursion
- Selective path level for recursion
- Watcher monitoring (info, match, nomatch)
- New tests are added

### Changed

- Important code refactoring (file_deletion, file_creation, file_alteration)
- :bug: Fix issue #10 "LuajitError: builtin/fio.lua:544: pathname is absent #10"
- Refactoring watcher.test.lua

## [0.1.1-172-gb7309a3] - 2021-04-07

First release of watcher for advanced file watcher.

### Added

- Advanced File Deletion
- Advanced File Creation
- Advanced File Alteration
- Plugin schema
- Examples
