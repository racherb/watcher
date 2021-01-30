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

> **Watcher** for watches the changes in the file system, variables and data records.

# Watcher

Watcher is an open source system to automate the detection of changes in the system, facilitating the integration of processes, workflows and the development of monitoring applications.

Detecting changes to the file system or data structures in memory is useful for developers of security applications, resource monitoring or process integration.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Requires **tarantool** >= 1.6.8.0
- Build Requires: **tarantool-devel** >= 1.6.8.0

## Instaling Watcher

### From LuaRocks

```Shell
luarocks install https://raw.githubusercontent.com/racherb/watcher/master/warcher-scm-1.rockspec --local
```

### From Linux Repository

#### Ubuntu

> Precise | Trusty | Xenial | Yakkety | Zesty

```Bash
apt update
apt install watcher
```

## From Source

Download watcher from ...

## Running the tests

```Bash
prove -v ./test/watcher.test.lua
```

## Getting Started

Create a watcher to detect file deletion:

```Lua
--Defining file watcher for deletions
fw = require('watcher').file
fw.deletion({'/path/to/file'})
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
