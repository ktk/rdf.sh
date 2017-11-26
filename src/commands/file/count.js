
const common = require('../../common')

exports.command = 'count <file>'
exports.desc = 'count distinct triples'
exports.handler = countCommand

function countCommand (argv) {
    common.init(argv)
    common.execLegacy(['count', argv.file])
}

