const chalk = require('chalk');
const common = require('../common');
exports.command = 'ns <prefixes..>'
exports.desc = 'resolve prefixes and return namespace declarations'
exports.builder = {
  format: {
    alias: 'f',
    default: 'plain',
    choices: ['plain', 'sparql', 'turtle', 'jsonld', 'json']
  }
}
exports.handler = function (argv) {
  common.DEBUG('ns command called with prefixes', argv.prefixes, 'and format(s)', argv.format);
}
