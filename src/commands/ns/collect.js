
const common = require('../../common')

exports.command = 'collect'
exports.desc = 'collects prefix declarations of a list of ttl/n3 files'
exports.handler = nsCollectCommand

function nsCollectCommand (argv) {
    common.init(argv)
    common.execLegacy(['nscollect'])
}

