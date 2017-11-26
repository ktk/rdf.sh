
exports.command = 'file <command>'
exports.desc = 'Work with RDF files (turtle, ntriples, ...)'
exports.builder = function (yargs) {
    return yargs
        .commandDir('file')
        .example('$0 file count doap.ttl', 'count the unique triple in the file doap.ttl')
        .epilog('All of the <file> parameter can be absolute URLs too.')
}
exports.handler = function (argv) {}
