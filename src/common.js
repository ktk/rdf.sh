
var _ = require('lodash')
var chalk = require('chalk');
var logSymbols = require('log-symbols');
var path = require('path');
var fs = require('fs');
var isWebUri = require('valid-url').isWebUri
var process = require('process');
var exec = require('child_process').exec;
var stdout = require('process').stdout;

var packageDirectory = path.join(path.dirname(fs.realpathSync(__filename)), '../');

const name = require('../package.json').name;
exports.name = name
const version = require('../package.json').version;
exports.version = version

var VERBOSE_LEVEL = 0


function OUT(output) { console.log(output) }
exports.OUT = OUT;

function WARN() {
    console.error(
        logSymbols.warning,
        chalk.bold.apply(null, arguments)
    )
}
exports.WARN = WARN;

function ERROR() {
    console.error(
        logSymbols.error,
        chalk.bold.red.apply(null, arguments)
    )
}
exports.ERROR = ERROR;

function INFO() {
    VERBOSE_LEVEL >= 1 && console.error(
        logSymbols.info,
        chalk.green.apply(null, arguments)
    )
}
exports.INFO = INFO;

function DEBUG() {
    VERBOSE_LEVEL >= 2 && console.error(
        logSymbols.info,
        chalk.dim.apply(null, arguments)
    )
}
exports.DEBUG = DEBUG;

function execLegacy(legacyCommand) {
    if (_.isArray(legacyCommand)) {
        legacyCommand = Array.from(legacyCommand).join(' ')
    }
    var command = packageDirectory + '/rdf-legacy.bash ' + legacyCommand
    DEBUG('try to excute:', command)
    exec(command, (error, commandOutput, commandErrorOutput) => {
        if (error) {
            ERROR('Execution of wrapped command "', legacyCommand, '" went wrong.')
            console.log(err);
            return;
        }

        // the *entire* stdout and stderr (buffered)
        if (commandOutput.length != 0) {
            stdout.write(commandOutput);
        }
        if (commandErrorOutput.length != 0) {
            console.error(commandErrorOutput);
        }
    });
}
exports.execLegacy = execLegacy;

function checkFileQnameUrl(string) {
    if(!fs.existsSync(string) && !isWebUri(string)) {
        ERROR(string, 'is neither a file nor a valid web URL')
        process.exit(1)
    } else {
        return string
    }
}
exports.checkFileQnameUrl = checkFileQnameUrl

function init(argv) {
    VERBOSE_LEVEL = argv.verbose
    INFO(name, version, 'command', argv._, 'initialized');
}
exports.init = init


