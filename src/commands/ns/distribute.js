
const common = require('../../common')

exports.command = 'distribute [files..]'
exports.desc = 'distributes prefix declarations from one file to a list of other ttl/n3 files'
exports.handler = nsDistributeCommand

function nsDistributeCommand (argv) {
    common.init(argv)
    common.execLegacy(['nsdist', argv.files])
}

