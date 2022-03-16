# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2.4-1-e6c5e8f] - 2022-03-15

### Added

- Add stability check and other small changes
- Pass stability only if it comes as a parameter
- Add spinner for wait in to command line
- Add new test plan
- Add WATCHER_PATH

### Changed

- Correction for bulk file deletion
- Correction for math when is zero
- Consolidate by watcher kind
- Unify wlist consolidate
- File name correction
- Convert ignore list to table
- Add ref to module watcher-cli

## [v0.2.3-12-ga58e484] - 2022-02-26

### Changed

- "ansicolors" dependency added

### Fixed

- Fix issue #15 "Bad argument #1 to 'pairs' (table expected, got string)" Convert "ignore" string list input to table in command line interface.

## [0.2.3-0-g1277cb1] - 2022-02-23

### Added

- Command line interface
- Non-color command line support according to no-color.org
- New functionality for naming watchers
- New functionality for watcher deletion
- New functionality "string2wlist" to convert a file list string to an internally used table type.
- The "sleep" functionality is exposed at the module level
- You can now ignore files from the list to be watched

### Changed

- Functionalities "deduplicate" and "consolidate" are now exposed at module level
- The run watcher procedure can now receive a watcher parameter or by its watcher id
- Watcher status standardization
- Code refactoring and other small changes

## [v0.2.2-1-g0e40729] - 2021-05-12

### Changed

- Small code refactoring for better performance and issues fixed

### Fixed

- :bug: Fix issue #13 "close func not work for alteration when the file not exist #13"
- :bug: Fix issue #12 "Monit's nomatch always returns the additional number of elements that are search patterns. #12"

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
- Refactoring watcher.test.lua

### Fixed

- :bug: Fix issue #10 "LuajitError: builtin/fio.lua:544: pathname is absent #10"

## [0.1.1-172-gb7309a3] - 2021-04-07

First release of watcher for advanced file watcher.

### Added

- Advanced File Deletion
- Advanced File Creation
- Advanced File Alteration
- Plugin schema
- Examples
