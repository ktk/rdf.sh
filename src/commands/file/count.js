
const common = require('../../common')

exports.command = 'count <file>'
exports.desc = 'count distinct triples'
exports.handler = countCommand
exports.builder = function (yargs) {
    return yargs
        .positional(
            'file', {
                describe: 'document to count, can be an URL',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            }
        )
}

function countCommand (argv) {
    common.init(argv)
    common.execLegacy(['count', argv.file])
}

