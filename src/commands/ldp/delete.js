
const common = require('../../common')

exports.command = 'delete <uri>'
exports.desc = 'deletes an existing linked data resource'
exports.handler = ldpDeleteCommand

function ldpDeleteCommand (argv) {
    common.init(argv)
    common.execLegacy(['delete', argv.uri])
}

