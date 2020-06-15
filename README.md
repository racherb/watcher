![Watcher](watcher.png)

![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/racherb/watcher/master)
![GitHub version](https://badge.fury.io/gh/racherb%2Fwatcher.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/racherb/watcher)
![GitHub contributors](https://img.shields.io/github/contributors/racherb/watcher.svg)
![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)
![GitHub top language](https://img.shields.io/github/languages/top/racherb/watcher)
![Travis](https://travis-ci.com/racherb/watcher.svg?branch=master)
![GitHub repo size](https://img.shields.io/github/repo-size/racherb/watcher)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/racherb/watcher)
![GitHub issues](https://img.shields.io/github/issues/racherb/watcher)
![GitHub closed issues](https://img.shields.io/github/issues-closed/racherb/watcher)
![GitHub stars](https://img.shields.io/github/stars/racherb/watcher?style=social)
![GitHub forks](https://img.shields.io/github/forks/racherb/watcher?style=social)

**Watcher** for watches the changes in the file system, variables and data records.

> :warning: *This project is under development and not yet ready for production.*

# Watcher

Detecting changes to the file system or data structures in memory is useful for developers of security applications, resource monitoring or process integration.

## Supported Platforms

### Distributions

- ...

### Archictectures

- i386
- x86_64
- armhf (32-bit ARM with hardware floating-point)
- aarch64 (64-bit ARM)

## Getting Started

Create a watcher to detect file deletion:

```Lua
--Defining file watcher for deletions
fw = require('watcher').file
fw.deletion({'/path/to/file'})
```

### Prerequisites

- Requires **tarantool** >= 1.6.8.0
- Build Requires: **tarantool-devel** >= 1.6.8.0

### Installing

#### From Luarocks

```Shell
luarocks install https://raw.githubusercontent.com/racherb/watcher/master/warcher-scm-1.rockspec --local
```

#### From Linux Repository

**Ubuntu** Precise | Trusty | Xenial | Yakkety | Zesty

```Bash
apt update
apt install watcher
```

**Debian** Wheezy | Jessie | Stretch | Sid

```Bash
apt update
apt install watcher
```

**Fedora** 24 | 25 | Rawhide

```Bash
apt update
apt install watcher
```

**Centos** 6 | 7

#### From source

Download watcher from ...

## Running the tests

Explain how to run the automated tests for this system

```Bash
prove -v ./test/watcher.test.lua
```

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Use cases

#### FileWatcher

- [x] File deletion
- [x] File creation
- [x] File alteration
- [ ] File access
- [ ] File mode
- [ ] File users
- [ ] Corruption of files

#### DataWatcher

- [ ] Data deletion
- [ ] Data creation
- [ ] Data alteration

#### FlagWatcher

...

## Built With

* [Lua](https://www.lua.org/) - Is a powerful, efficient, lightweight, embeddable scripting language.
* [Tarantool](https://maven.apache.org/) - Is a powerful fast data platform that comes with an in-memory database and an integrated application server.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/racherb/watcher/tags).

## Authors

* **Raciel Hernández** - *Personal Blog* - [Fixing the Web](https://racherb.github.io/)

See also the list of [contributors](https://github.com/racherb/watcher/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details

## Acknowledgments

* TODO
