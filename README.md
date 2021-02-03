![Watcher](watcher.png)

![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/racherb/watcher/master)
![GitHub version](https://badge.fury.io/gh/racherb%2Fwatcher.svg)
![GitHub contributors](https://img.shields.io/github/contributors/racherb/watcher.svg)
![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)
![GitHub top language](https://img.shields.io/github/languages/top/racherb/watcher)
![Travis](https://travis-ci.com/racherb/watcher.svg?branch=master)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/racherb/watcher)

> **Watcher** for watches the changes in the file system, variables and data records.

# Watcher

Watcher is an open source system to automate the detection of changes in the system, facilitating the integration of processes, workflows and the development of monitoring applications.

Detecting changes to the file system or data structures in memory is useful for developers of security applications, resource monitoring or process integration.

## Prerequisites

### Supported platforms

- POSIX Compliant: **Unix**, **Macosx**, **Linux**, **Freebsd**
- POSIX for Windows: **Cygwin**, **Microsoft POSIX subsystem**, **Windows Services for UNIX**, **MKS Toolkit**

### Tarantool

Watcher runs on Tarantool. Before you begin, ensure you have met the following requirements:

- Requires **tarantool** >= 1.6.8.0
- Build Requires: **tarantool-devel** >= 1.6.8.0

## Instaling Watcher

### From Utility Tarantool

Install watcher through Tarantool's tarantoolctl command:

```Shell
tarantoolctl rocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec
```

### From LuaRocks

Make sure you have Luarocks installed first, if you need to install it follow the instructions in the following link: [luarocks/wiki](https://github.com/luarocks/luarocks/wiki/Download)

From the terminal run the following command:

```Shell
luarocks install https://raw.githubusercontent.com/racherb/watcher/master/watcher-scm-1.rockspec --local
```

## Running the tests

The execution of the tests will take between 3 and 10 minutes approximately. This time is required in the simulation of file generation, modification and deletion.

```Bash
prove -v ./test/watcher.test.lua
```

or

```Bash
./test/watcher.test.lua
```

## Getting Started

### Using Watcher is very simple

Create a watcher to detect file deletion:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.deletion({'/path/to/file'})
```

Create a watcher to detect file creation:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.creation({'/path/to/file'})
```

Create a watcher to detect file alteration:

```Lua
tarantool> fw = require('watcher').file
tarantool> fw.creation({'/path/to/file'})
```

### But it is also very powerful

Watcher for *all* files with extension *txt* in the temporary folder */tmp*. But (there is always a but) you only want to detect the deletion of the first 2 of those 5 files that were recently modified.

Note: The */tmp* directory may contain hundreds of files with *.txt* extension.

```Lua
tarantool> pattern = {'/tmp/*.txt'} 
tarantool> MAXWAIT = 120  --Maximum waiting time for the file (seconds)
tarantool> INTERVAL = 1   --File check frequency (seconds)
tarantool> O_BY = 'MA'    --Sorted in ascending order by date of modification
tarantool> N_ITEMS = 5    --Observe the n cases in the ordered list
tarantool> N_MATCH = 2    --Detects the first ''2' files to be deleted

tarantool> fwt.deletion(pattern, MAXWAIT, INTERVAL, {O_BY, N_ITEMS, N_MATCH})
```

## Under the hood

--TODO

## Use cases

### File Watcher

- [x] Advanced File deletion
- [x] Advanced File creation
- [x] Advanced File alteration

### Examples

#### When the file arrives: process

This is a simple example of automatic processing of a file once the file is created in a given path. This particular case works in blocking mode.

```Lua
#!/usr/bin/env tarantool

local fw = require('watcher').file

--Function that processes a file after it arrives
local function process_file(the_file)
    print('Waiting for the file ...')
    if fw.creation(the_file).ans then
        print('Orale! The file is ready')
        --Write your code here!
        --...
    else
        print('Ugh! The file has not arrived')
    end
end

--Processes the '/tmp/fileX.txt' file: Blocking mode
process_file({'/tmp/fileX.txt'})

```

A non-blocking mode of execution would be to use Tarantool fibers. For example, replacing the last two lines of the above code with the following:

```Lua
--Processes the '/tmp/fileX.txt' file: Non-Blocking mode
local fiber = require('fiber')
fiber.create(process_file, {'/tmp/fileX.txt'})
```

## Built With

* [Lua](https://www.lua.org/) - Is a powerful, efficient, lightweight, embeddable scripting language.
* [Tarantool](https://maven.apache.org/) - Is a powerful fast data platform that comes with an in-memory database and an integrated application server.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/racherb/watcher/tags).

## Authors

* **Raciel Hernández**

* See also the list of [contributors](https://github.com/racherb/watcher/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
