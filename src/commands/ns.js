
const common = require('../common');
const clipboardy = require('clipboardy');

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
    common.init(argv)
    common.INFO('command ns called with prefixes', argv.prefixes, 'and format(s)', argv.format)

    var result = 'this needs to be done'
    common.OUT(result)
    clipboardy.writeSync(result);
    common.WARN('command ns finished')
}
