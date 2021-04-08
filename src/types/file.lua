
local OUTPUT = {}

OUTPUT.WATCH_LIST_NOT_VALID = 'WATCH_LIST_NOT_VALID'
OUTPUT.NOTHING_FOR_WATCH = 'NOTHING_FOR_WATCH'
OUTPUT.MAXWAIT_NOT_VALID = 'MAXWAIT_NOT_VALID'
OUTPUT.INTERVAL_NOT_VALID = 'INTERVAL_NOT_VALID'
OUTPUT.MINSIZE_NOT_VALID = 'MINSIZE_NOT_VALID'
OUTPUT.STABILITY_NOT_VALID = 'STABILITY_NOT_VALID'
OUTPUT.CHECK_SIZE_INTERVAL_NOT_VALID = 'CHECK_SIZE_INTERVAL_NOT_VALID'
OUTPUT.ITERATIONS_NOT_VALID = 'ITERATIONS_NOT_VALID'
OUTPUT.NOVELTY_NOT_VALID = 'NOVELTY_NOT_VALID'
OUTPUT.DATE_FROM_NOT_VALID = 'DATE_FROM_NOT_VALID'
OUTPUT.DATE_UNTIL_NOT_VALID = 'DATE_UNTIL_NOT_VALID'
OUTPUT.N_MATCH_NOT_VALID = 'N_MATCH_NOT_VALID'
OUTPUT.N_CASES_NOT_VALID = 'N_CASES_NOT_VALID'
OUTPUT.ALTER_WATCH_NOT_VALID = 'ALTER_WATCH_NOT_VALID'

OUTPUT.ALL_DELETED = 'ALL_DELETED'
OUTPUT.MATCH_DELETED = 'MATCH_DELETED'
OUTPUT.MATCH_NOT_DELETED = 'MATCH_NOT_DELETED'
OUTPUT.NOTHING_DELETED = 'NOTHING_DELETED'

local WATCHER = {}

WATCHER.FILE_CREATION = 'FWC'
WATCHER.FILE_DELETION = 'FWD'
WATCHER.FILE_ALTERATION = 'FWA'

WATCHER.PREFIX = 'FW'
WATCHER.MAXWAIT = 60            --seconds
WATCHER.INTERVAL = 0.5          --seconds
WATCHER.CHECK_INTERVAL = 0.5    --seconds
WATCHER.ITERATIONS = 10         --loops

local FILE = {}

FILE.NOT_YET_CREATED = '_'                  --The file has not yet been created
FILE.FILE_PATTERN = 'P'                     --This is a file pattern
FILE.HAS_BEEN_CREATED = 'C'                 --The file has been created
FILE.IS_NOT_NOVELTY = 'N'                   --The file is not an expected novelty
FILE.UNSTABLE_SIZE = 'U'                    --The file has an unstable file size
FILE.UNEXPECTED_SIZE = 'S'                  --The file size is unexpected
FILE.DISAPPEARED_UNEXPECTEDLY = 'D'         --The file has disappeared unexpectedly
FILE.DELETED = 'X'                          --The file has been deleted
FILE.NOT_EXISTS = 'T'                       --The file does not exist
FILE.NOT_YET_DELETED = 'E'                  --The file has not been deleted yet
FILE.NO_ALTERATION = '0'                    --The file has not been modified
FILE.ANY_ALTERATION = '1'                   --The file has been modified
FILE.CONTENT_ALTERATION = '2'               --The content of the file has been altered
FILE.SIZE_ALTERATION = '3'                  --The file size has been altered
FILE.CHANGE_TIME_ALTERATION = '4'           --The ctime of the file has been altered
FILE.MODIFICATION_TIME_ALTERATION = '5'     --The mtime of the file has been altered
FILE.INODE_ALTERATION = '6'                 --The number of inodes has been altered
FILE.OWNER_ALTERATION = '7'                 --The owner of the file has changed
FILE.GROUP_ALTERATION = '8'                 --The group of the file has changed

return {
    FILE = FILE,
    OUTPUT = OUTPUT,
    WATCHER = WATCHER
}