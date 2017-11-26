
const common = require('../../common')

exports.command = 'diff <file1> <file2>'
exports.desc = 'diff of all triples from two RDF files'
exports.handler = diffCommand

function diffCommand (argv) {
    common.init(argv)
    common.execLegacy(['diff', argv.file1, argv.file2])
}

