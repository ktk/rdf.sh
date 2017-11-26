
const common = require('../../common')

exports.command = 'turtleize <file>'
exports.desc = 'outputs an RDF file in turtle, using as much as possible prefix declarations'
exports.handler = turtleizeCommand

function turtleizeCommand (argv) {
    common.init(argv)
    common.execLegacy(['turtleize', argv.file])
}

