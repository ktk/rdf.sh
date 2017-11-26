
const common = require('../../common')
const clipboardy = require('clipboardy')
var request = require('request-promise');

var _ = require('lodash')

exports.command = 'lookup <prefixes..>'
exports.desc = 'resolve prefixes and return namespace declarations'
exports.builder = {
  format: {
    alias: 'f',
    default: 'plain',
    choices: ['plain', 'sparql', 'turtle', 'jsonld', 'json']
  }
}
exports.handler = nsLookupCommand

function formatNamespaces (namespaces, formats) {
    return namespaces
}

function nsLookupCommand (argv) {
    common.init(argv)

    var fetchedPrefixes = Array.from(argv.prefixes).join(',')
    var options = {
        url: `http://prefix.cc/${fetchedPrefixes}.file.json`,
        headers: {
            'User-Agent': `${common.name} ${common.version}`
        },
        json: true
    };
    request(options)
        .then(function (result) {
            formattedResult = formatNamespaces(result, argv.format)
            common.OUT(formattedResult)
            // clipboardy.writeSync(formattedResult);
        })
        .catch(function (error) {
            common.ERROR(`prefixes ${fetchedPrefixes} not found`)
        });
}

