
const common = require('../../common')

exports.command = 'list <uri>'
exports.desc = 'list resources in a namespace'
exports.handler = listCommand

function listCommand (argv) {
    common.init(argv)
    common.execLegacy(['list', argv.uri])
}

