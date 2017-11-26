
const common = require('../../common')

exports.command = 'delete <graph> [store]'
exports.desc = 'delete a graph'
exports.handler = gspDeleteCommand

function gspDeleteCommand (argv) {
    common.init(argv)
    common.execLegacy(['gsp-delete', argv.graph, argv.store])
}

