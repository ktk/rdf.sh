
const common = require('../../common')

exports.command = 'desc <uri>'
exports.desc = 'output the description of a resource'
exports.handler = descCommand

function descCommand (argv) {
    common.init(argv)
    common.execLegacy(['desc', argv.uri])
}

