
const chalk = require('chalk');
const logSymbols = require('log-symbols');

var VERBOSE_LEVEL = 0

function init(argv) {
    VERBOSE_LEVEL = argv.verbose
}
exports.init = init


function OUT(output) { console.log(output) }
function WARN() {
    console.error(
        logSymbols.warning,
        chalk.bold.apply(null, arguments)
    )
}
function ERROR() {
    console.error(
        logSymbols.error,
        chalk.bold.red.apply(null, arguments)
    )
}
function INFO() {
    VERBOSE_LEVEL >= 1 && console.error(
        logSymbols.info,
        chalk.green.apply(null, arguments)
    )
}
function DEBUG() {
    VERBOSE_LEVEL >= 2 && console.error(
        logSymbols.info,
        chalk.dim.apply(null, arguments)
    )
}

exports.OUT = OUT;
exports.WARN = WARN;
exports.ERROR = ERROR;
exports.INFO = INFO;
exports.DEBUG = DEBUG;

