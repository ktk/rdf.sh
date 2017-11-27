
const common = require('../../common')
const fs = require('fs')

exports.command = 'diff <file1> <file2>'
exports.desc = 'diff of all triples from two RDF files'
exports.handler = diffCommand
exports.builder = function (yargs) {
    return yargs
        .positional(
            'file1', {
                describe: 'first document you want to compare',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            })
        .positional(
            'file2', {
                describe: 'second document you want to compare',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            })
}

function diffCommand (argv) {
    common.init(argv)
    common.execLegacy(['diff', argv.file1, argv.file2])
}

