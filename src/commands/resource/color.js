
const common = require('../../common')

exports.command = 'color <uri>'
exports.desc = 'create a html color for a resource'
exports.handler = colorCommand

function colorCommand (argv) {
    common.init(argv)
    common.execLegacy(['color', argv.uri])
}

