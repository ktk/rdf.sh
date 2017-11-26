
const common = require('../../common')

exports.command = 'skolemize <file> [namespace]'
exports.desc = 'Not a real skolemization but materialises bnodes as IRIs and outputs the file turtleized. The second parameter is an optional namespace IRI.'
exports.handler = skolemizeCommand

function skolemizeCommand (argv) {
    common.init(argv)
    common.execLegacy(['skolemize', argv.file, argv.namespace])
}

