
const common = require('../../common')

exports.command = 'split <file> <size> [command]'
exports.desc = 'split an RDF file into pieces of max X triple and outputs the piece filenames'
exports.handler = diffCommand

function diffCommand (argv) {
    common.init(argv)
    common.execLegacy(['split', argv.file, argv.size, argv.command])
}

