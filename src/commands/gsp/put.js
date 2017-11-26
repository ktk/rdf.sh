
const common = require('../../common')

exports.command = 'put <graph> <file> [store]'
exports.desc = 'delete and re-create a graph'
exports.handler = gspPutCommand

function gspPutCommand (argv) {
    common.init(argv)
    common.execLegacy(['gsp-put', argv.graph, argv.file, argv.store])
}

