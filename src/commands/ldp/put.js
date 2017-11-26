
const common = require('../../common')

exports.command = 'put <uri>'
exports.desc = 'replaces an existing linked data resource'
exports.handler = ldpPutCommand

function ldpPutCommand (argv) {
    common.init(argv)
    common.execLegacy(['put', argv.uri])
}

