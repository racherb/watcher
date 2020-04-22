package = 'watcher'
version = 'scm-1'
source  = {
    url    = 'https://github.com/racherb/watcher/archive/master.zip';
    branch = 'master';
}

description = {
    summary  = "Watcher for watches the changes in the file system, variables and data records.";
    detailed = [[
    Detecting changes to the file system or data structures in memory 
    is useful for developers of security applications, 
    resource monitoring or process integration with Tarantool.
    ]];
    homepage = 'https://github.com/racherb/watcher.git';
    maintainer = "Raciel Hernández <racielhb@protonmail.com>";
    license  = 'MIT';
}

-- Lua version and other packages on which this one depends;
-- Tarantool currently supports strictly Lua 5.1
dependencies = {
    'lua == 5.1';
}

build = {
    type = 'builtin';
    modules = {
        ['watcher'] = 'watcher/watcher.lua';
        ['file_watcher'] = 'watcher/file_watcher.lua';
    }
}
-- vim: syntax=lua ts=4 sts=4 sw=4 et
