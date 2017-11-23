
const chalk = require('chalk');

var VERBOSE_LEVEL = 0

function init(argv) {
    VERBOSE_LEVEL = argv.verbose
}
exports.init = init

function WARN() { console.error(chalk.bold.apply(null, arguments)); }
function ERROR() { console.error(chalk.bold.red.apply(null, arguments)); }
function INFO() { VERBOSE_LEVEL >= 1 && console.error(chalk.green.apply(null, arguments)); }
function DEBUG() { VERBOSE_LEVEL >= 2 && console.error(chalk.dim.apply(null, arguments)); }

exports.WARN = WARN;
exports.ERROR = ERROR;
exports.INFO = INFO;
exports.DEBUG = DEBUG;

