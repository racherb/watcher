package = 'watcher'
version = 'scm-1'
source  = {
    url    = 'https://github.com/racherb/watcher.git';
    branch = 'master';
}

description = {
    summary  = "Watcher for files, directories, objects and services";
    detailed = [[
    Watcher for files, directories, objects and services.
    For tarantool.
    ]];
    homepage = 'https://github.com/racherb/watcher.git';
    maintainer = "Raciel Hernández <racielhb@gmail.com>";
    license  = 'MIT';
}

-- Lua version and other packages on which this one depends;
-- Tarantool currently supports strictly Lua 5.1
dependencies = {
    'lua == 5.1';
}

-- build options and paths for the package;
-- this package distributes modules in pure Lua, so the build type = 'builtin';
-- also, specify here paths to all Lua modules within the package
-- (this package contains just one Lua module named 'watcher')
build = {
    type = 'builtin';
    modules = {
        ['watcher'] = 'watcher/init.lua';
    }
}
-- vim: syntax=lua ts=4 sts=4 sw=4 et
