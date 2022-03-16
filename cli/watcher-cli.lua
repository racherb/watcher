#!/usr/bin/env tarantool

local watcher_path = os.getenv('WATCHER_PATH')..'src/?.lua'
package.path = package.path .. ';'..watcher_path

local color = require('ansicolors')
local fiber = require('fiber')

local WATCHER = require('types.file').WATCHER
local STATE = require('types.file').STATE
local fwa = require('watcher').file
local mon = require('watcher').monit
local core = require('watcher').core

local string = require('string')

local cli = {
    title = "The Watcher Command Line Interface",
    tag = "watcher",
    slogan = 'Watcher for better Observability',
    description = "Watcher",
    version = "watcher-0.1.1",
    stability = 'Experimental',
    target = "Linux-x86_64-Release",
    author = "Raciel Hernandez B.",
    release = '20211228'
}

local logo_color = {
    "                   _       _               ",
    "    __      ____ _| |_ ___| |__   ___ _ __ ",
    "    \\ \\ /\\ / / _` | __/ __| '_ \\ / _ \\ '__| \t "..cli.title,
    "     \\ V  V / (_| | || (__| | | |  __/ |   \t %{dim}"..cli.version.."%{reset green bright}",
    "      \\_/\\_/ \\__,_|\\__\\___|_| |_|\\___|_|   \t %{dim}MIT License",
    "       %{white}Watcher for better Observability"
}

local logo = {
    "                   _       _               ",
    "    __      ____ _| |_ ___| |__   ___ _ __ ",
    "    \\ \\ /\\ / / _` | __/ __| '_ \\ / _ \\ '__| \t "..cli.title,
    "     \\ V  V / (_| | || (__| | | |  __/ |   \t "..cli.version,
    "      \\_/\\_/ \\__,_|\\__\\___|_| |_|\\___|_|   \t MIT License",
    "       Watcher for better Observability"
}

local style = {}
local help = {}

local stop_spinner = false

local function show_spinner(txt)
    stop_spinner = false
    local spin_seq = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'}
    local nbck = string.rep('\b', string.len(txt))
    while not stop_spinner == true do
        for i=1,#spin_seq do
            io.write(txt)
            io.write(color('%{bright yellow}'..spin_seq[i]..nbck..'\b%{reset}'))
            io.flush()
            core.sleep(0.1)
        end
    end
end

--[[emojis and icons
    ✔
    ✖
    🐣
    ❌
    ✅
    🔐
    🤏
    🔑
    💭
    ❓
--]]

function style.logo(theme)
    local _theme = theme or 'default'
    if _theme == 'default' then
        return table.concat(
            {
                '%{green bright}',
                table.concat(logo_color,'\n'),
                '%{reset}'
        },'')
    else
        return table.concat({table.concat(logo,'\n')},'')
    end
end

function style.topic(txt, theme)
    local _theme = theme or 'default'
    if _theme == 'default' then
        return table.concat({'%{white bright}🔸', txt, ':%{reset}'},'')
    else
        return txt..':'
    end
end

function style.syntax(cmd, params, comment, theme)
    local _theme = theme or 'default'
    local _comment = comment or ''
    if _theme == 'default' then
        return table.concat(
            {
                '\t%{blue}+ %{white bright}',
                cmd,
                '%{reset}%{magenta}',
                params,
                '%{reset}',
                _comment
            },
        '')
    else
        return table.concat({'\t+ ', cmd, params, _comment}, '')
    end
end

function style.prompt(cmd, flags, subcmd, args, comment, theme)
    local _theme = theme or 'default'
    local _comment = comment or ''
    if _theme == 'default' then
        return table.concat(
            {
                '\t%{dim}$ %{reset white bright}', cmd,
                '%{reset dim magenta}', flags,
                '%{reset green}', subcmd, args,
                '%{reset dim}',
                _comment,
                '%{reset}'
            },
        '')
    else
        return table.concat({'\t$ ', cmd, flags, subcmd, args, _comment}, '')
    end
end

function style.ident(txt, n, theme, prefix, emoji, link)
    local _theme = theme or 'default'
    local _emoji = emoji or ''
    local _prefix = prefix or ''
    local _link = link or ''
    if _theme == 'default' then
        return table.concat(
            {
                string.rep(' ', n),
                '%{dim}',
                _prefix,
                txt,
                '%{reset}',
                _emoji,
                '%{blue}',
                _link,
                '%{reset}'
            }, '')
    else
        return table.concat({string.rep(' ', n), txt, _link}, '')
    end
end

function style.version(theme)
    local _theme = theme or 'default'
    if _theme == 'default' then
        return table.concat(
            {
                '%{dim}version:%{reset} ',
                cli.tag, '-', cli.version
            },'')
    else
        return table.concat(
            {
                'version: ',
                cli.tag, '-', cli.version
            }, '')
    end
end

function style.context(kind, flags, theme)
    local _theme = theme or 'default'
    if _theme == 'default' then
        return table.concat(
            {
                '        ',
                '%{bright green}',
                kind,
                ':%{reset}\t',
                flags,
                '%{reset}'
            }, '')
    else
        return table.concat({kind, ':', flags}, '')
    end
end

function style.defaults(flag, default, note, theme)
    local _theme = theme or 'default'
    local _note = note or ''
    if _theme == 'default' then
        return table.concat(
            {
                '\t%{magenta}--',
                flag,
                ' %{reset}',
                '\t%{white}',
                default,
                '%{reset}',
                '\t\t%{dim}',
                _note,
                '%{reset}'
            }, '')
    else
        return table.concat(
            {
                '\t--',
                flag,
                ' \t',
                default,
                '\t\t',
                note
            }, '')
    end
end

function style.itemdata(item, value, level, theme)
    local _theme = theme or 'default'
    local _level = level or 1
    local tabsize = _level*2
    if _theme == 'default' then
        return table.concat({
            string.rep(' ', tabsize),
            '- ',
            '%{dim}',
            item,
            ': ',
            '%{reset blue}',
            value,
            '%{reset}',
        }, '')
    else
        return table.concat({
            string.rep(' ', tabsize),
            '- ',
            item,
            ': ',
            value,
        }, '')
    end
end

function style.itemheader(header, tab, theme)
    local thme = theme or 'default'
    if thme=='default' then
        return '%{bright}'..table.concat(header, tab)..'%{reset}'
    else
        return table.concat(header, tab)
    end
end

function help.usage(theme, topic)
    local usage = {
        '',
        style.topic('USAGE', theme),
        '',
        style.prompt(cli.tag, ' [<flags>]', topic, ' <args>', '', theme)
    }
    if topic == ' new' then
        usage[#usage+1] = ''
        usage[#usage+1] = style.prompt(
            cli.tag,
            ' --FILE_CREATION [<flags>]', topic,
            ' <wlist>',
            ' \t#Create a new watcher for detect file creation',
            theme
        )
        usage[#usage+1] = style.prompt(
            cli.tag,
            ' --FILE_DELETION [<flags>]', topic,
            ' <wlist>',
            ' \t#Create a new watcher for detect file deletion',
            theme
        )
        usage[#usage+1] = style.prompt(
            cli.tag,
            ' --FILE_ALTERATION [<flags>]', topic,
            ' <wlist>',
            ' \t#Create a new watcher for detect file alteration',
            theme
        )
    end
    return usage
end

function help.tostar(theme)
    return {
        '',
        style.ident(
            'To start working with "watcher", run the following command:',
            8,
            theme,
            '',
            '🐣'
        ),
        '',
        style.prompt(
            'watcher',
            '',
            ' new',
            '',
            ' #This allows you to create a new watcher specification',
            theme),
        '',
    }
end

function help.common(theme)
    return {
        '',
        style.topic("WHAT'S NEXT?", theme),
        '',
        style.ident('The most commonly used commands are:', 4, theme),
        '',
        style.syntax('watcher', ' run', '\t\t Run a watcher', theme),
        style.syntax('watcher', ' mon', '\t\t For monitoring watcher', theme),
        '',
        style.ident(
            ' For more information visit the website: ',
            8,
            theme,
            '❓',
            '',
            'https://watcher.readthedocs.io/en/latest/'
        )
    }
end

function help.commands(theme)
    return {
        '',
        style.topic('AVAILABLE COMMANDS', theme),
        '',
        style.syntax('watcher', ' new', '\t\t Create a new watcher', theme),
        style.syntax('watcher', ' run', '\t\t Run a watcher', theme),
        style.syntax('watcher', ' mon', '\t\t For monitoring watcher', theme),
        style.syntax('watcher', ' info', '\t\t Gets information from a previously executed watcher', theme),
        style.syntax('watcher', ' ls', '\t\t List existing watchers', theme),
        style.syntax('watcher', ' rm', '\t\t Removes a given watcher', theme),
        style.syntax('watcher', ' match', '\t\t Gets the list of items detected by watcher', theme),
        style.syntax('watcher', ' nomatch', '\t Gets the list of items not detected by watcher', theme),
        --style.syntax('watcher', ' config', '\t Set watcher configuration', theme),
        style.syntax('watcher', ' name', '\t\t Name a watcher', theme),
        --style.syntax('watcher', ' env', '\t\t Environment', theme),
        '',
        style.ident(
            ' To get help on how to run a specific command, run:',
            8,
            theme,
            '🔖'
        ),
        '',
        style.prompt('watcher', '', ' <command>', ' --help', '', theme)
    }
end

function help.flags(theme, scope)
    local _scope = scope or 'short'
    local flags = {
        '',
        style.topic('FLAGS', theme),
        '',
        '\t --help,        -h \t Help for watcher',
        '\t --version,     -V \t Show watcher version',
        '\t --no-color,    -n \t No colorize output',
        '\t --no-save,     -x \t Does not save watcher run data',
        '\t --verbose,     -v \t Enable verbose logging',
        --'\t --interactive, -i \t Enable interactive mode',
        '\t --defaults,    -d \t Defaults values',
        '',
        '\t --FILE_CREATION   \t Watcher for file creation',
        '\t --FILE_DELETION   \t Watcher for file deletion',
        '\t --FILE_ALTERATION \t Watcher for file alteration',
    }

    if _scope == 'short' then
        flags[#flags+1] = '\t ..(and more)'
        flags[#flags+1] = ''
        flags[#flags+1] = style.ident(
            ' To see all the system flags, run the following command:',
            8,
            theme,
            '💡'
        )
        flags[#flags+1] = ''
        flags[#flags+1] = style.prompt('watcher', '', '', ' --flags', '\t\t# Displays all system flags', theme)
        flags[#flags+1] = style.prompt(
            'watcher', '', '', ' --flags <command>', '\t# Displays only the flags that apply to a given command',
            theme
        )
        flags[#flags+1] = ''
    elseif _scope == 'long' then
        flags[#flags+1] =  ''
        flags[#flags+1] = '\t --maxwait <value>   \t Maximum wait time in seconds'
        flags[#flags+1] = '\t --interval <value>  \t Verification interval for watcher in seconds'
        flags[#flags+1] = '\t --minsize <value>   \t Value of the minimum expected file size'
        flags[#flags+1] = '\t --frecuency <value>   \t Defines the frequency of checking the file once it has arrived'
        flags[#flags+1] = '\t --iterations <value>  \t The number of iterations used to determine the stability of the file'
        flags[#flags+1] = '\t --minage <value>   \t Date and time "from" of the novelty of the file'
        flags[#flags+1] = '\t --maxage <value>   \t Date and time "to" of the novelty of the file'
        flags[#flags+1] = '\t --sort <value>   \t Ordering method of the wacth list'
        flags[#flags+1] = '\t --cases <value> \t Number of cases to observe from the wlist'
        flags[#flags+1] = '\t --match <value> \t Number of cases expected to satisfy the search'
        flags[#flags+1] = '\t --recursive <value> \t Boolean indicating whether or not to activate the recursive mode on directory'
        flags[#flags+1] = '\t --levels <value> \t Numerical table indicating the levels of depth to be evaluated in the directory structure'
        flags[#flags+1] = '\t --hidden <value> \t Boolean indicating whether hidden files will be evaluated in the recursion'
        flags[#flags+1] = '\t --awhat <value> \t Type of file alteration to be observed'
        flags[#flags+1] = '\t --ignore <list> \t List of cases to be ignore fron watchable list'
        flags[#flags+1] = ''
        flags[#flags+1] = style.ident(
            ' Application context of the flags by "kind" of watcher:',
            8,
            theme,
            '✨'
        )
        flags[#flags+1] = ''
        flags[#flags+1] = style.context(
            ' - FILE_CREATION',
            ' --maxwait, --interval, --minsize, --frecuency, --iterations, --minage, --maxage, --match --ignore',
            theme
        )
        flags[#flags+1] = style.context(
            ' - FILE_DELETION',
            ' --maxwait, --interval, --sort, --cases, --match, --recursive, --levels, --hidden --ignore',
            theme
        )
        flags[#flags+1] = style.context(
            ' - FILE_ALTERATION',
            ' --maxwait, --interval, --awhat, --match --ignore',
            theme
        )
        flags[#flags+1] = ''
        flags[#flags+1] = style.ident(
            ' To know the default values of the flags run:',
            8,
            theme,
            '🔖'
        )
        flags[#flags+1] = ''
        flags[#flags+1] = style.prompt('watcher', '', '', ' --defaults', '\t\t# Displays the default values of all the flags', theme)
        flags[#flags+1] = style.prompt('watcher', '', '', ' --defaults <command>', '\t# Displays the default values of only the flags for the given command', theme)
        flags[#flags+1] = ''
    end

    return table.concat(flags, '\n')

end

function help.args(theme, topic)
    local _theme = theme or 'default'
    if topic == 'new' then
        if _theme == 'default' then
            return {
                '',
                style.topic('ARGS', theme),
                '',
                '\t%{green}wlist%{reset} \tWatch list\t%{blackbg red dim}<mandatory>%{reset}%{dim} Value list as follows:%{reset green} "/path/to/file_a, /path/to/file_b, /path/fo/*, ..."%{reset}',
                '',
            }
        else
            return {
                '',
                style.topic('ARGS', theme),
                '',
                '\tWatch list\t <mandatory> Value list as follows: "/path/to/file_a, /path/to/file_b, /path/fo/*, ..."',
                '',
            }
        end
    end
end

function help.defaults(scope, theme)
    local _scope = scope or 'general'
    local defaults = {
        '',
            style.topic('DEFAULTS', theme),
            '',
            style.defaults('maxwait', '60 seconds', '', theme),
            style.defaults('interval', '0.5 seconds', '', theme)
    }
    if _scope == 'general' then
        defaults[#defaults+1] = style.defaults('minsize', '0 Bytes', 'Ignore file size', theme)
        defaults[#defaults+1] = style.defaults('frecuency', '1 second', '', theme)
        defaults[#defaults+1] = style.defaults('iterations', '15', '', theme)
        defaults[#defaults+1] = style.defaults('minage', '0', 'Expected minimum age of the novelty of the file. Zero ignores the minimum age', theme)
        defaults[#defaults+1] = style.defaults('maxage', '0', 'Expected maximum age of the novelty of the file. Zero ignores the maximum age', theme)
        defaults[#defaults+1] = style.defaults('match', '0', 'Zero is referring to all files detected', theme)
        defaults[#defaults+1] = style.defaults('sort', "\t'NS'", 'NS means "No sort" for watcher list', theme)
        defaults[#defaults+1] = style.defaults('cases', '0', 'Zero for check all files in the list', theme)
        defaults[#defaults+1] = style.defaults('recursion', 'false', 'Recursive mode is off', theme)
        defaults[#defaults+1] = style.defaults('levels', '"{0}"', 'Referred to the root directory', theme)
        defaults[#defaults+1] = style.defaults('hidden', 'false', 'false for ignore hidden files', theme)
        defaults[#defaults+1] = style.defaults('awhat', '1', 'Value of 1 indicates: check for any file alteration', theme)
        defaults[#defaults+1] = style.defaults('ignore', '', 'Empty value: Do not ignore any cases', theme)
    end

    defaults[#defaults+1] = ''

    return table.concat(defaults,'\n')
end

function help.print(theme, scope)
    local _scope = scope or 'general'
    if _scope == 'general' then
        print(color(style.logo(theme)))
        print(color(table.concat(help.usage(theme, ' <command>'), '\n')))
        print(color(table.concat(help.tostar(theme), '\n')))
        print(color(table.concat(help.common(theme), '\n')))
        print(color(table.concat(help.commands(theme), '\n')))
        print(color(help.flags(theme, 'short'), '\n'))
    elseif _scope == 'new' then
        print(color(table.concat(help.usage(theme, ' new'), '\n')))
        print(color(table.concat(help.args(theme, 'new'), '\n')))
        print(color(help.flags(theme, 'long'), '\n'))
    end
end

local function wid2string(wid)
    return ((tostring(wid)):rstrip('ULL'))
end

local wargs = {...}

local command = {}

--If wid is nil then list awatchers
--else list watchablesf
function command.list(wid)
    return mon.list(wid)
end

function command.remove(wid)
    return core.remove(wid)
end

local function split(str, delimiter)
    local result = {};
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        --table.insert(result, match);
        result[#result+1] = match
    end
    return result;
end

local function get_wid(val)
    if tonumber(val) then
        return tonumber(val)
    else
        local nametag = split(val, ':')
        local name = nametag[1]
        local tag = nametag[2]
        if name=='' and tag=='' then
            return val
        else
            return core.widbyname(name, tag)
        end
    end
end

function command.name(wid, strname)
    local nametag = split(strname, ':')
    local name = nametag[1] or ''
    local tag = nametag[2] or ''
    return core.name(tonumber(wid), name, tag)
end

function command.info(wid)
    return mon.info(wid)
end

local flags_lst = {}
flags_lst['--no-color']     = 'n'
flags_lst['-n']             = 'n'
flags_lst['--no-save']      = 'x'
flags_lst['-x']             = 'x'
flags_lst['--version']      = 'V'
flags_lst['-V']             = 'V'
flags_lst['--help']         = 'h'
flags_lst['-h']             = 'h'
--flags_lst['--interactive']  = 'i'
--flags_lst['-i']             = 'i'
flags_lst['--verbose']      = 'v'
flags_lst['-v']             = 'v'
flags_lst['--robot']        = 'r'
flags_lst['-r']             = 'r'
flags_lst['--flags']        = 'f'
flags_lst['-f']             = 'f'
flags_lst['--defaults']     = 'd'
flags_lst['-d']             = 'd'
flags_lst['--maxwait']      = 'maxwait'
flags_lst['--interval']     = 'interval'
flags_lst['--minsize']      = 'minsize'
flags_lst['--frecuency']    = 'frecuency'     --stability
flags_lst['--iterations']   = 'iterations'    --stability
flags_lst['--minage']       = 'minage'        --novelty
flags_lst['--maxage']       = 'maxage'        --novelty
flags_lst['--match']        = 'match'
flags_lst['--sort']         = 'sort'          --options
flags_lst['--cases']        = 'cases'         --options
flags_lst['--match']        = 'match'         --options
flags_lst['--recursive']    = 'recursive'     --recursion
flags_lst['--levels']       = 'levels'        --recursion
flags_lst['--hidden']       = 'hidden_files'  --recursion
flags_lst['--awhat']        = 'awhat'
flags_lst['--ignore']       = 'ignore'        --ignore cases fron watchable list

flags_lst['--FILE_CREATION']   = 'creation'
flags_lst['--FILE_DELETION']   = 'deletion'
flags_lst['--FILE_ALTERATION'] = 'alteration'

flags_lst['--CHECK_STABILITY'] = 'c_s'

local defaults = {
    maxwait = WATCHER.MAXWAIT,
    interval = WATCHER.INTERVAL,
    minsize = 0,
    sort = WATCHER.NO_SORT,
    cases = 0,
    match = 0,
    recursive = false,
    frecuency = WATCHER.CHECK_INTERVAL,
    iterations = WATCHER.ITERATIONS,
    minage = 0,
    maxage = WATCHER.INFINITY_DATE,
    levels = {0},
    hidden = false,
    awhat = '1',
    ignore = '', --{''},
    forever = 9e10
}

local cmd_lst = {}
cmd_lst["new"]              = 'new'
cmd_lst["run"]              = 'run'
cmd_lst["mon"]              = 'mon'
cmd_lst["info"]             = 'info'
cmd_lst["file"]             = 'file'
cmd_lst["name"]             = 'name'
cmd_lst["list"]             = 'list'
cmd_lst["ls"]               = 'ls'   --alias for command list
cmd_lst["rm"]               = 'rm'   --remove watcher
cmd_lst["exec"]             = 'exec' --execute (new+run)

local _theme = 'default'
--local _interactive = false
local _version = false
local _verbose = false
local _robot = false
local _nocolor
local _nosave
local _help
local _flags
local _defaults
local _command
local _cargs = {}
local _maxwait = defaults.maxwait
local _interval = defaults.interval
local _minsize = defaults.minsize
local _frecuency = nil
local _iterations = nil
local _minage = defaults.minage
local _maxage = defaults.maxage
local _sort = defaults.sort
local _cases = defaults.cases
local _match = defaults.match
local _recursive = defaults.recursive
local _levels = defaults.levels
local _hidden = defaults.hidden
local _awhat = defaults.awhat
local _ignore = defaults.ignore
local _creation
local _alteration
local _deletion
local _check_stability = false

local wcoll = {} --Watchers collection

local function translate(term)
    if term==WATCHER.FILE_ALTERATION then
        return 'FILE_ALTERATION'
    elseif term==WATCHER.FILE_CREATION then
        return 'FILE_CREATION'
    elseif term==WATCHER.FILE_DELETION then
        return 'FILE_DELETION'
    elseif term==STATE.RUNNING then
        return 'running'
    elseif term==STATE.COMPLETED then
        return 'completed'
    elseif term==STATE.UNSTARTED then
        return 'unstarted'
    elseif term=='0' then
        return 'NO_ALTERATION'
    elseif term=='1' then
        return 'ANY_ALTERATION'
    elseif term=='' then
        return '<none>'
    elseif term=='_' then
        return 'NOT_YET_CREATED'
    elseif term=='C' then
        return 'HAS_BEEN_CREATED'
    elseif term=='E' then
        return 'NOT_DELETED'
    elseif term=='X' then
        return 'DELETED'
    else
        return term
    end

end

local function print_wheader(header, theme)
    print(color(style.itemheader(header, '\t', theme)))
end

local function print_witem(nw, theme)
    local thme = theme or 'default'
    local swid = wid2string(nw.wid)
    if thme =='default' then
        print(color(table.concat(
            {
                translate(nw.kind),
                swid,
                tostring(#(nw.list)),
                '%{red dim}\b',
                'unstarted',
                '%{reset}'
        }, '\t')))
    else
        print(table.concat(
            {
                translate(nw.kind),
                swid,
                tostring(#(nw.list)),
                'unstarted'
            }, '\t'))
    end
end

local function print_winfo(inf, theme)
    local thme = theme or 'default'
    if thme=='default' then
        print(color(table.concat(
            {
                '- wid: %{bright}',
                wid2string(inf.wid),
                '\n%{reset}  kind: ',
                tostring(inf.kind),
                '\n  state: ',
                translate(inf.status),
                '\n  what: ',
                inf.what,
                '\n  match: ',
                inf.match,
                '\n  nomatch: ',
                inf.nomatch,
                '\n  answ: %{dim}',
                tostring(inf.ans),
                '%{reset}'
            }, '')))
    else
        print(table.concat(
            {
                '- wid: ',
                wid2string(inf.wid),
                '\n- kind: ',
                tostring(inf.kind),
                '\n- state: ',
                translate(inf.status),
                '\n- what: ',
                inf.what,
                '\n- match: ',
                inf.match,
                '\n- nomatch: ',
                inf.nomatch,
                '\n- answ: ',
                tostring(inf.ans)
            }, ''))
    end
end

local function parser()
    local j = 0
    for i=1,#wargs do
        --Scan flags
        if flags_lst[wargs[i]]=='n' or os.getenv ("NO_COLOR") then
            _nocolor = 'nocolor'
            _theme = 'nocolor'
        elseif flags_lst[wargs[i]]=='x' then
            _nosave = true
        elseif flags_lst[wargs[i]]=='V' then
            _version = true
        elseif flags_lst[wargs[i]]=='f' then
            _flags = true
        elseif flags_lst[wargs[i]]=='d' then
            _defaults = true
        elseif flags_lst[wargs[i]]=='v' then
            _verbose = true
            print('Verbose mode is activated')
        elseif flags_lst[wargs[i]]=='r' then
            _robot = true
        elseif flags_lst[wargs[i]]=='c_s' then
            _check_stability = true
            print('Enabling file stability check')
        elseif flags_lst[wargs[i]]=='h' then
            _help = true
        elseif flags_lst[wargs[i]]=='creation' then
            _creation = true
        elseif flags_lst[wargs[i]]=='deletion' then
            _deletion = true
        elseif flags_lst[wargs[i]]=='alteration' then
            _alteration = true
        elseif flags_lst[wargs[i]]=='maxwait' then
            _maxwait = wargs[i+1]
        elseif flags_lst[wargs[i]]=='interval' then
            _interval = wargs[i+1]
        elseif flags_lst[wargs[i]]=='minsize' then
            _minsize = wargs[i+1]
        elseif flags_lst[wargs[i]]=='frecuency' then
            _frecuency = wargs[i+1]
        elseif flags_lst[wargs[i]]=='iterations' then
            _iterations = wargs[i+1]
        elseif flags_lst[wargs[i]]=='minage' then
            _minage = wargs[i+1]
        elseif flags_lst[wargs[i]]=='maxage' then
            _maxage = wargs[i+1]
        elseif flags_lst[wargs[i]]=='match' then
            _match = wargs[i+1]
        elseif flags_lst[wargs[i]]=='sort' then
            _sort = wargs[i+1]
        elseif flags_lst[wargs[i]]=='cases' then
            _cases = wargs[i+1]
        elseif flags_lst[wargs[i]]=='recursive' then
            _recursive = wargs[i+1]
        elseif flags_lst[wargs[i]]=='levels' then
            _levels = wargs[i+1]
        elseif flags_lst[wargs[i]]=='hidden' then
            _hidden = wargs[i+1]
        elseif flags_lst[wargs[i]]=='awhat' then
            _awhat = wargs[i+1]
        elseif flags_lst[wargs[i]]=='ignore' then
            _ignore = wargs[i+1]
        else
            --It's a command?
            if cmd_lst[wargs[i]]=='new' then
                _command = 'new'
            elseif cmd_lst[wargs[i]]=='run' then
                _command = 'run'
            elseif cmd_lst[wargs[i]]=='mon' then
                _command = 'mon'
            elseif cmd_lst[wargs[i]]=='info' then
                _command = 'info'
            elseif cmd_lst[wargs[i]]=='match' then
                _command = 'match'
            elseif cmd_lst[wargs[i]]=='nomatch' then
                _command = 'nomatch'
            elseif cmd_lst[wargs[i]]=='config' then
                _command = 'config'
            elseif cmd_lst[wargs[i]]=='name' then
                _command = 'name'
            elseif cmd_lst[wargs[i]]=='file' then
                _command = 'file'
            elseif cmd_lst[wargs[i]]=='ls' or cmd_lst[wargs[i]]=='list' then
                _command = 'list'
            elseif cmd_lst[wargs[i]]=='rm' then
                _command = 'rm'
            elseif cmd_lst[wargs[i]]=='exec' then
                _command = 'exec'
            else
                --Capture args
                if _command then
                    _cargs[j+1] = wargs[i]
                    j = j + 1
                else
                    local a = string.find(wargs[i], '-', 1, 1)
                    if not a then
                        --print(wargs[i-1])
                        if not (
                               (_maxwait and wargs[i-1]=='--maxwait' and _maxwait == wargs[i])
                            or (_interval and wargs[i-1]=='--interval' and _interval == wargs[i])
                            or (_minsize and wargs[i-1]=='--minsize' and _minsize == wargs[i])
                            or (_frecuency and wargs[i-1]=='--frecuency' and _frecuency == wargs[i])
                            or (_iterations and wargs[i-1]=='--iterations' and _iterations == wargs[i])
                            or (_minage and wargs[i-1]=='--minage' and _minage == wargs[i])
                            or (_maxage and wargs[i-1]=='--maxage' and _maxage == wargs[i])
                            or (_match and wargs[i-1]=='--match' and _match == wargs[i])
                            or (_sort and wargs[i-1]=='--sort' and _sort == wargs[i])
                            or (_cases and wargs[i-1]=='--cases' and _cases == wargs[i])
                            or (_recursive and wargs[i-1]=='--recursive' and _recursive == wargs[i])
                            or (_levels and wargs[i-1]=='--levels' and _levels == wargs[i])
                            or (_hidden and wargs[i-1]=='--hidden' and _hidden == wargs[i])
                            or(_awhat and wargs[i-1]=='--awhat' and _awhat == wargs[i])
                            or(_awhat and wargs[i-1]=='--ignore' and _ignore== wargs[i])
                        ) then
                            print(color('%{bright red}ERR7001: %{reset}Invalid entry. The command "'.. wargs[i]..'" is unknown'))
                            print(color('%{bright}   HINT: %{reset dim}Some of the available commands are:%{green dim} new, run, mon, info, match, nomatch, ..'))
                            print(color('%{bright}   HINT: %{reset dim}Run %{green dim}watcher --help%{reset} for help'))
                            os.exit(7001)
                        end
                    else
                        print(color('%{bright red}ERR7002: %{reset}Invalid entry. The flag "'.. wargs[i]..'" is unknown'))
                        print(color('%{bright}   HINT: %{reset dim}The flags that are supported are: %{green dim} -h, -v, -i, -n, -e, -b, -r, ..'))
                        print(color('%{bright}         %{reset dim}Run %{green dim}watcher --flags%{reset} to display watcher flags'))
                        os.exit(7002)
                    end
                end
            end
        end
    end

    if _version then
        print(color(style.version(_theme)))
    end

    if _help or #(wargs)==0 or (#(wargs)==1 and _nocolor) then
        print(help.print(_theme, _command))
    elseif not _help and _flags then
        print(color(help.flags(_theme, 'long')))
    elseif not _help and _defaults then
        print(color(help.defaults('general', _theme)))
    elseif not _help and (_flags and _defaults) then
        print(color(help.flags(_theme, 'long')))
        print(color(help.defaults('general', _theme)))
    end

    if _command then --and not _interactive then
        if _command == 'new' and #(_cargs) == 1 then
            local wlist = core.string2wlist(_cargs[1])
            local cparms = {}
            cparms.recursion = _recursive
            cparms.levels = _levels
            cparms.hidden = _hidden
            cparms.ignored = core.string2wlist(_ignore)
            if _creation then
                local nw = core.create(
                    wlist,
                    WATCHER.FILE_CREATION,
                    nil,
                    cparms
                )
                wcoll[#wcoll+1] = nw
            end
            if _alteration then
                local nw = core.create(
                    wlist,
                    WATCHER.FILE_ALTERATION,
                    nil,
                    cparms
                )
                wcoll[#wcoll+1] = nw
            end
            if _deletion then
                local nw = core.create(
                    wlist,
                    WATCHER.FILE_DELETION,
                    nil,
                    cparms
                )
                wcoll[#wcoll+1] = nw
            end
        elseif _command == 'new' and #(_cargs) == 0 then
            print('You must specify the parameters for the "new" command')
        elseif _command == 'name' and #(_cargs) == 2 then
            command.name(_cargs[2], _cargs[1])
        elseif _command == 'name' and #(_cargs) < 2 then
            print('Debe especificar un nombre repo:tag y un watcher id')
        elseif _command=='list' then
            if not _cargs[1] then --list awatchers
                local lst = command.list()
                print_wheader(
                    {
                        'REPOSITORY',
                        'TAG',
                        '\tWATCHER ID',
                        '\tKIND',
                        'CREATED',
                        '\tOBSERVABLES'
                    }, _theme)
                for i=1,#lst do
                    print(table.concat(
                        {
                            string.ljust(translate(lst[i][8]), 11, ' '),
                            '\t', string.ljust((translate(lst[i][9])), 11, ' '),
                            '\t', wid2string(lst[i][1]),
                            '\t', lst[i][2],
                            '\t', os.date("%Y-%m-%d", wid2string(lst[i][4]/1e9)),
                            '\t', lst[i][3]
                        }, '')
                    )
                end
                print('✔ '..#lst..' watchers found')
            else --List watchables
                local wid = get_wid(_cargs[1])
                if wid then
                    local lst = command.list(tonumber(wid))
                    print_wheader(
                    {
                        string.ljust('OBJECT', 90),
                        '\tMATCH',
                        'STATE',
                        '\tDETECTED'
                    }, _theme)
                    for i=1,#lst do
                        local detected
                        if lst[i][6]~=0 then
                            detected = tostring(os.date("%Y-%m-%d %X", wid2string(lst[i][6]/1e9)))
                        else
                            detected = '<none>'
                        end
                        print(table.concat(
                            {
                                '- '..string.ljust(lst[i][2], 90),
                                '\t\t', tostring(lst[i][4]),
                                '\t', string.ljust(translate(tostring(lst[i][5])), 16),
                                '', detected
                            }, '')
                        )
                    end
                    print('✔ '..#lst..' watchables have been found for the given watcher')
                else
                    --TODO: Normalize output
                    print('The name:tag does not exist')
                end
            end
        elseif _command == 'run' and #(_cargs) == 1 then
            local wid = get_wid(_cargs[1])
            if wid then
                local winf = mon.info(wid)
                local kind = winf.kind
                if not winf.err then
                    local cparms = {}
                    cparms.recursion = _recursive
                    cparms.levels = _levels
                    cparms.hidden = _hidden
                    cparms.ignored = core.string2wlist(_ignore)
                    local wparms = {}
                    wparms.maxwait = tonumber(_maxwait)
                    wparms.interval = tonumber(_interval)
                    wparms.match = tonumber(_match)
                    if kind == WATCHER.FILE_CREATION then
                        wparms.minsize = tonumber(_minsize)
                        wparms.match = tonumber(_match)
                        local stability = {}
                        if _check_stability == true then
                            if _frecuency then
                                stability.frecuency = tonumber(_frecuency)
                            else
                                stability.frecuency =defaults.frecuency
                            end
                            if _iterations then
                                stability.iterations = tonumber(_iterations)
                            else
                                stability.iterations = defaults.iterations
                            end
                        else
                            stability = nil
                        end
                        wparms.stability = stability
                        local novelty = {}
                        novelty.minage = tonumber(_minage)
                        novelty.maxage = tonumber(_maxage)
                        wparms.novelty = novelty
                    elseif kind == WATCHER.FILE_DELETION then
                        wparms.sort = _sort
                        wparms.cases = tonumber(_cases)
                    elseif kind == WATCHER.FILE_ALTERATION then
                        wparms.what = _awhat
                    end
                    local run_ans = core.run(wid, wparms, cparms)
                    print(table.concat({
                        'Watcher is ',
                        run_ans.stt,
                        ' on fiber ',
                        run_ans.fid
                    }, ''))
                    print('Estimated maximum time for this execution: '.._maxwait..'s')
                    if _verbose==true and #cparms.ignored~=0 then
                        print('Ignoring files:'.._ignore)
                    end
                    fiber.create(show_spinner, '..Running:')
                    local cwf = core.waitfor(wid, wparms.maxwait)
                    stop_spinner = true
                    if cwf.err then
                        print('An error occurred while executing the File Watcher')
                        print('ERR:'..cwf.err)
                        --exit code
                    else
                        print('The File Watcher has been successfully completed')
                        print('Answer:'..tostring(cwf.ans))
                    end
                else
                    --TODO: Normalizar exit code para el error
                    print(winf.err)
                end
            else
                --TODO: Normalizar exito code para el error
                print('The name:tag does not exist')
                --exit code
            end
        elseif _command == 'exec' and #(_cargs) == 1 then
            local wlist = core.string2wlist(_cargs[1])
            if _creation then
                if _verbose==true then
                    if _ignore~='' then
                        print('Ignoring files:'.._ignore)
                    end
                end
                local stability = {}
                        if _check_stability == true then
                            if _frecuency then
                                stability.frecuency = tonumber(_frecuency)
                            else
                                stability.frecuency =defaults.frecuency
                            end
                            if _iterations then
                                stability.iterations = tonumber(_iterations)
                            else
                                stability.iterations = defaults.iterations
                            end
                        else
                            stability = nil
                        end
                local fwc = fwa.creation(
                    wlist,
                    tonumber(_maxwait),
                    tonumber(_interval),
                    tonumber(_minsize),
                    stability,
                    {
                        minage = _minage,
                        maxage = _maxage
                    },
                    tonumber(_match),
                    {
                        recursion = _recursive,
                        levels = _levels,
                        hidden = _hidden,
                    },
                    core.string2wlist(_ignore)
                )
                fiber.create(show_spinner, '..Running:')
                local wf_exec = core.waitfor(fwc.wid, tonumber(_maxwait))
                stop_spinner = true
                if wf_exec.err then
                    print('An error occurred while executing the File Watcher')
                    print('ERR:'..wf_exec.err)
                    --exit code
                else
                    print('The File Watcher has been successfully completed')
                    print('Answer:'..tostring(wf_exec.ans))
                end
                if _nosave then
                    local wid = get_wid(wf_exec.wid)
                    if not command.remove(wid) then
                        print('An error occurred while trying to forget (--nosave) the data')
                    end
                end
            elseif _alteration then
                local fwal = fwa.alteration(
                    wlist,
                    tonumber(_maxwait),
                    tonumber(_interval),
                    _awhat,
                    tonumber(_match),
                    {
                        recursion = _recursive,
                        levels = _levels,
                        hidden = _hidden,
                    },
                    core.string2wlist(_ignore)

                )
                fiber.create(show_spinner, '..Running:')
                local wf_exec = core.waitfor(fwal.wid, tonumber(_maxwait))
                stop_spinner = true
                if wf_exec.err then
                    print('An error occurred while executing the File Watcher')
                    print('ERR:'..wf_exec.err)
                    --exit code
                else
                    print('The File Watcher has been successfully completed')
                    print('Answer:'..tostring(wf_exec.ans))
                end
            elseif _deletion then
                local fwd = fwa.deletion(
                    wlist,
                    tonumber(_maxwait),
                    tonumber(_interval),
                    {
                        sort = _sort,
                        cases = tonumber(_cases),
                        match = tonumber(_match)
                    },
                    {
                        recursive = _recursive,
                        levels = _levels,
                        hidden = _hidden
                    },
                    core.string2wlist(_ignore)
                )
                fiber.create(show_spinner, '..Running:')
                local wf_exec = core.waitfor(fwd.wid, tonumber(_maxwait))
                stop_spinner = true
                if wf_exec.err then
                    print('An error occurred while executing the File Watcher')
                    print('ERR:'..wf_exec.err)
                    --exit code
                else
                    print('The File Watcher has been successfully completed')
                    print('Answer:'..tostring(wf_exec.ans))
                end
            end
        elseif _command == 'info' and #(_cargs) == 1 then
            local wid = get_wid(_cargs[1])
            if wid then
                local inf = command.info(wid)
                if not inf.err then
                    print_winfo(inf, _theme)
                else
                    --TODO: Normalizar exito code para el error
                    print(inf.err)
                end
            else
                --TODO: Normalizar exito code para el error
                print('The name:tag does not exist')
            end
        elseif _command == 'rm' and #(_cargs) == 1 then
            local wid = get_wid(_cargs[1])
            if wid then
                local ans = command.remove(wid)
                if not ans then
                    print('Watcher could not be deleted or no longer exists')
                end
            else
                --TODO: Normalizar exit code para el error
                print('The name:tag does not exist')
            end
        elseif _command == 'file' then
            print('File FILE FILE')
        end
    --elseif not _command then
    --    print('You must specify a command')
    end

    --Sumarize output for watcher file
    local wcreated = 0
    if #wcoll == 1 then
        local _nw = wcoll[1]
        if _nw.ans == true then
            print_wheader({'KIND', '\tWID', '\t\tITEMS', 'STATE'}, _theme)
            print_witem(_nw, _theme)
            wcreated = wcreated + 1
        else
            print('The creation of the watcher for has failed')
        end
    elseif #wcoll > 1 then
        print_wheader({'KIND', '\tWID', '\t\tITEMS', 'STATE'}, _theme)
        for i=1,#wcoll do
            local _nw = wcoll[i]
            if _nw.ans == true then
                print_witem(_nw, _theme)
                wcreated = wcreated + 1
            else
                print('The creation of the watcher has failed')
            end
        end
    end

    if wcreated==0 and #wcoll~=0 then
        print('No watcher has been created')
    elseif wcreated==1 then
        print('✔ A watcher has been successfully created')
    elseif wcreated>0 then
        print('✔ '..wcreated ..' watchers have been successfully created')
    end

    os.exit(0)

end

if _verbose then
    print('Verbose mode is activated')
end

parser()

--if _robot then
--    print('Modo robot activado')
--end

--if _maxwait then
--    print(_maxwait)
--end



--if _command=='help' then
    --help.print(_theme)
--end