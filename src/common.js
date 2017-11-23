
const yargs = require('yargs');
const chalk = require('chalk');

var argv = yargs
  .commandDir('commands')
  .count('verbose')
  .alias('v', 'verbose')
  .demandCommand()
  .example('$0 ns skos', 'Get the typical namespace for the skos prefix')
  .help()
  .wrap(72)


VERBOSE_LEVEL = 2
function WARN() { VERBOSE_LEVEL >= 1 && console.error(chalk.bold.apply(null, arguments)); }
function DEBUG() { VERBOSE_LEVEL >= 2 && console.error(chalk.dim.apply(null, arguments)); }

exports.argv = argv
exports.WARN = WARN;
exports.DEBUG = DEBUG;

argv.argv
