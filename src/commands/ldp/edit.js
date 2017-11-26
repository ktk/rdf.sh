
const common = require('../../common')

exports.command = 'edit <uri>'
exports.desc = 'edit the content of an existing linked data resource (GET + PUT)'
exports.handler = ldpEditCommand

function ldpEditCommand (argv) {
    common.init(argv)
    common.execLegacy(['edit', argv.uri])
}

