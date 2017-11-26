
const common = require('../../common')

exports.command = 'get <graph> [store]'
exports.desc = 'get a graph'
exports.handler = gspGetCommand

function gspGetCommand (argv) {
    common.init(argv)
    common.execLegacy(['gsp-get', argv.graph, argv.store])
}

