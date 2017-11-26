
const common = require('../../common')

exports.command = 'get <uri>'
exports.desc = 'fetches an URL as RDF to stdout (tries accept header)'
exports.handler = ldpGetCommand

function ldpGetCommand (argv) {
    common.init(argv)
    common.execLegacy(['get', argv.uri])
}

