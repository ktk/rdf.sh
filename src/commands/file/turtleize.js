
const common = require('../../common')

exports.command = 'turtleize <file>'
exports.desc = 'outputs an RDF file in turtle, using as much as possible prefix declarations'
exports.handler = turtleizeCommand
exports.builder = function (yargs) {
    return yargs
        .positional(
            'file', {
                describe: 'document to pretty print, can be an URL',
                coerce: common.checkFileQnameUrl,
                type: 'string'
            })
}

function turtleizeCommand (argv) {
    common.init(argv)
    common.execLegacy(['turtleize', argv.file])
}

