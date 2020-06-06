
local OUTPUT = {}

OUTPUT.WATCH_LIST_NOT_VALID = 'WATCH_LIST_NOT_VALID'
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

OUTPUT.ALL_DELETED = 'ALL_DELETED'
OUTPUT.MATCH_DELETED = 'MATCH_DELETED'
OUTPUT.MATCH_NOT_DELETED = 'MATCH_NOT_DELETED'
OUTPUT.NOTHING_DELETED = 'NOTHING_DELETED'

local FILE = {}

FILE.NOT_YET_CREATED = '_'
FILE.FILE_PATTERN = 'P'
FILE.HAS_BEEN_CREATED = 'C'
FILE.IS_NOT_NOVELTY = 'N'
FILE.UNSTABLE_SIZE = 'U'
FILE.UNEXPECTED_SIZE = 'S'
FILE.DISAPPEARED_UNEXPECTEDLY = 'D'
FILE.DELETED = 'X'
FILE.NOT_EXISTS = 'T'
FILE.NOT_YET_DELETED = 'E'

return {
    FILE = FILE,
    OUTPUT = OUTPUT
}