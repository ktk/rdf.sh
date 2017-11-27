
const common = require('../../common')

exports.command = 'skolemize <file> [namespace]'
exports.desc = 'Materialises bnodes as IRIs'
exports.handler = skolemizeCommand
exports.builder = function (yargs) {
    return yargs
        .positional(
            'file', {
                describe: 'document to split, can be an URL',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            })
        .positional(
            'namespace', {
                describe: 'optional namespace prefix for the minted bnode IRIs',
                type: 'string'
            })
}

function skolemizeCommand (argv) {
    common.init(argv)
    common.execLegacy(['skolemize', argv.file, argv.namespace])
}

