
const common = require('../../common')

exports.command = 'split <file> <size>'
exports.desc = 'split a file into pieces and output filenames'
exports.handler = splitCommand
exports.builder = function (yargs) {
    return yargs
        .positional(
            'file', {
                describe: 'document to split, can be an URL',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            })
        .positional(
            'size', {
                describe: 'the number of triples you want to have in each piece',
                type: 'number'
            })
}

function splitCommand (argv) {
    common.init(argv)
    common.execLegacy(['split', argv.file, argv.size, argv.command])
}

