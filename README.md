
# 👁️‍🗨️ Watcher

**Watcher** for watches the changes in the file system.

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/3983/badge)](https://bestpractices.coreinfrastructure.org/projects/3983)
[![Luacheck](https://github.com/racherb/watcher/actions/workflows/luacheck.yml/badge.svg)](https://github.com/racherb/watcher/actions/workflows/luacheck.yml)
![Travis](https://travis-ci.org/racherb/watcher.svg?branch=master)
[![Documentation Status](https://readthedocs.org/projects/watcher/badge/?version=latest)](https://watcher.readthedocs.io/en/latest/?badge=latest)
![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)
![GitHub top language](https://img.shields.io/github/languages/top/racherb/watcher)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/racherb/watcher)

:warning: **WARNING:** *Watcher is currently in an unstable phase*.

Watcher is an open source system to automate the detection of changes in the system, facilitating the integration of processes, workflows and the development of monitoring applications.

Detecting changes to the file system or data structures in memory is useful for developers of security applications, resource monitoring or process integration.

:construction: [Documentation](https://racherb.github.io/watcher/) (*Under construction*)

## Key features

### File Watcher

- [x] Watcher for single files and directories
- [x] Watcher for different file groups
- [x] Watcher for file naming patterns
- [x] Watcher for Advanced File Deletion
- [x] Watcher for Advanced File Creation
- [x] Watcher for Advanced File Alteration
- [x] Non-blocking execution with tarantool fibers
- [x] Bulk file processing
- [x] :new: Blocking execution with "*waitfor*" function
- [x] :new: Decoupled execution between the creation of the watcher and its execution
- [x] Discrimination of files by sorting and quantity
- [x] Novelty detection for file creation
- [x] Watcher for any changes or alteration in the file system
- [x] Watcher for specific changes in the file system
- [x] Qualitative response for each observed file
- [x] Processing of large quantities of files
- [x] Validation of the stability of the file when it is created
- [x] Configuration of the file watcher conditions
- [x] Validation of the minimum expected size of a file
- [x] Detection of anomalies in the observation of the file
- [x] :new: Injection of atomic functions on the watcher list
- [x] :new: Folder recursion and selective path level
- [x] :new: Watcher monitoring (info, match, nomatch)

## Prerequisites

### Supported platforms

- POSIX Compliant: **Unix**, **Macosx**, **Linux**, **Freebsd**
- POSIX for Windows: **Cygwin**, **Microsoft POSIX subsystem**, **Windows Services for UNIX**, **MKS Toolkit**

### Tarantool

Watcher runs on Tarantool. Before you begin, ensure you have met the following requirements:

- Requires **tarantool** >= 1.7
- Build Requires: **tarantool-devel** >= 1.7

## Instaling Watcher

There are several ways to install watcher on your server. Choose the option that suits you best and ... go ahead! :blush:

### From Docker

#### Get Watcher container from a docker image

```Bash
docker pull racherb/watcher:latest
docker run -i -t racherb/watcher
```

#### Use docker volumes

If you want to look at the host or remote machine's file system then start a container with a volume.

The following example enables a volume on the temporary folder */tmp* of the host at path */opt/watcher/host/* of the container.

```Shell
docker run -i -t -v /tmp/:/opt/watcher/host/tmp racherb/watcher
```

> :sparkles: https://hub.docker.com/r/racherb/watcher

### Quick installation from DEB Package

Install the repository and package:

```Shell
curl -s https://packagecloud.io/install/repositories/iamio/watcher/script.deb.sh | sudo bash
sudo apt-get install watcher=0.2.1-1
```

Available for the following distributions:

- **Debian**: Lenny, Trixie, Bookworm, Bullseye, Buster, Stretch, Jessie
- **Ubuntu**: Cosmic, Disco, Hirsute, Groovy, Focal
- **ElementaryOS**: Freya, Loki, Juno, Hera

### Quick installation from RPM Package

Available for the following distributions:

- **RHEL**: 7, 6, 8
- **Fedora**: 29, 30, 31, 32, 33
- **OpenSuse**: 15.1, 15.2, 15.3, 42.1, 42.2, 42.3
- **SLES**: 12.4, 12.5, 15.0, 15.1, 15.2, 15.3

First install the repository:

```Shell
curl -s https://packagecloud.io/install/repositories/iamio/watcher/script.rpm.sh | sudo bash
```

Install the package:

- For RHEL and Fedora distros: `sudo yum install watcher-0.2.1-1.noarch`
- For Opensuse and Suse Linux Enterprise: `sudo zypper install watcher-0.2.1-1.noarch`

### Quick installation from Utility Tarantool

Install watcher through Tarantool's tarantoolctl command:

```Shell
tarantoolctl rocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec
```

### From LuaRocks

Make sure you have Luarocks installed first, if you need to install it follow the instructions in the following link: [luarocks/wiki](https://github.com/luarocks/luarocks/wiki/Download)

From the terminal run the following command:

```Shell
luarocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec
```

## Running the tests

The execution of the tests will take between 2 and 10 minutes approximately. This time is required in the simulation of file generation, modification and deletion.

```Bash
./test/watcher.test.lua
```

## Getting Started

### Using Watcher is very simple

Create a watcher to detect **file deletion**:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.deletion({'/path/to/file'})
```

Create a watcher to detect **file creation**:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.creation({'/path/to/file'})
```

Create a watcher to detect **file alteration**:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.alteration({'/path/to/file'})
```

### But it is also very powerful

Watcher for *all* files with extension *txt* in the temporary folder */tmp*. But (there is always a but) you only want to detect the deletion of the first 2 of those 5 files that were recently modified.

Note: The */tmp* directory may contain hundreds of files with *.txt* extension.

```Lua
tarantool> fw = require('watcher').file
tarantool> pattern = {'/tmp/*.txt'} 
tarantool> MAXWAIT = 120  --Maximum waiting time for the file [seconds}
tarantool> INTERVAL = 1   --File check frequency [seconds]
tarantool> ORDBY = 'MA'   --Sorted in ascending order by date of modification
tarantool> ITEMS = 5      --Observe the first 5 cases in the ordered list
tarantool> MATCH = 2      --Detects the first 2 files to be deleted
tarantool> fw.deletion(pattern, MAXWAIT, INTERVAL, {ORDBY, ITEMS, MATCH})
```

### :tv: Monit for explore watcher

Use monit to know the result of the watcher execution.

The following case is a file watcher for the detection of the creation of two files ('*/tmp/fileA*' and '*/tmp/fileB*'). One of them exists and the other has not been created yet.

The use of **monit** allows you to know the status of the watcher.

```Lua
tarantool> fw = require('watcher').file
tarantool> mon = require('watcher').monit
tarantool> os.execute('touch /tmp/fileA')              --Create fileA for demo
tarantool> fw.creation({'/tmp/fileA', '/tmp/fileB'})   --Create file watcher for fileA and fileB
---
- wid: 1618857178550065
  fid: 123
...
tarantool> mon.info(1618857178550065) --wid as param for monitoring result
---
- ans: waiting                        --'waiting' means that it has not yet been completed
  match: 1                            --A file has been found
  what: '{"/tmp/fileA","/tmp/fileB"}' --List of observable objects on request
  wid: 1618857178550065               --The watcher id
  type: FWC                           --Type of watcher, 'FWC' for file watcher creation
  nomatch: 1                          --A file was not found
  status: started                     --File watcher started
...
```

Once the watcher has finished we can know the final status. For example, for the same watcher id (wid) we get:

```Lua
tarantool> mon.info(1618857178550065)
---
- ans: false  --The watcher has finished but the conditions were not met
  match: 1
  what: '{"/tmp/fileA","/tmp/fileB"}'
  wid: 1618857178550065
  type: FWC
  nomatch: 1
  status: completed
...
```

To know the cases that satisfy the watcher criteria use the function 'match' and for those that do not, use the function 'nomatch'.

```Lua
tarantool> mon.match(1618857178550065)
---
- - [1618857178550065, '/tmp/fileA', 1618857178550662653, true, 'C', 1618857178651989852]
...
tarantool> mon.nomatch(1618857178550065)
---
- - [1618857178550065, '/tmp/fileB', 1618857178551146982, false, '_', 0]
...

```

### Examples

#### When the file arrives then process

This is a simple example of automatic processing of a file once the file is created in a given path. This particular case works in blocking mode using "waitfor" function.

```Lua
#!/usr/bin/env tarantool

local filewatcher = require('watcher').file
local waitfor = require('watcher').waitfor

--Function that processes a file after it arrives
local function process_file(the_file)
    print('Waiting for the file ...')
    local res = waitfor(
        filewatcher.creation(the_file).wid
    )
    if res.ans then
        print('Orale! The file ' .. the_file[1] .. ' is ready')
        --Write your code here!
        --...
        --...
    else
        print("'D'OH.! The file has not arrived")
    end
end

process_file({'/tmp/abc.x'})

os.exit()

```

By default watcher runs in non-blocking mode through tarantool fibers.

## Possible applications

- Workload automation
- Process integration
- System monitoring
- Backup and restore
- Data security

## Under the hood

:soon: *Comming soon*

## Built With

- [Lua](https://www.lua.org/) - Is a powerful, efficient, lightweight, embeddable scripting language.
- [Tarantool](https://maven.apache.org/) - Is a powerful fast data platform that comes with an in-memory database and an integrated application server.

## How to contribute?

There are many ways to contribute to Watcher:

- **Code** – Contribute to the code. We have components written in Lua and other languages.
- **Write** – Improve documentation, write blog posts, create tutorials or solution pages.
- **Q&A** – Share your acknowledgments at Stack Overflow with tag #watcher.* **Spread the word** – Share your accomplishments in social media using the #watcher hashtags.
- **Test** - Write a test

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

For style guide in Lua coding follow the suggestions at [Lua Style Guide](https://www.tarantool.io/en/doc/latest/dev_guide/lua_style_guide/).

### How to contribute to language connectors

Support is required for the construction of connectors that allow the use of watcher from different programming languages, for example:

- Node
- Python
- Go

### How to contribute to watcher plugins

Plugins allow you to extend watcher applications. If you want to write your own plugins based on watcher, follow the steps below:

...

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/racherb/watcher/tags).

## Discussions & Ideas

We’re using [Discussions](https://github.com/racherb/watcher/discussions) as a place to connect with other members of our community. We hope that you:

- Ask questions you’re wondering about.
- Share ideas.
- Engage with other community members.
- Welcome others and are open-minded. Remember that this is a community we build together 💪

## Authors

- **Raciel Hernández**

- See also the list of [contributors](https://github.com/racherb/watcher/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
