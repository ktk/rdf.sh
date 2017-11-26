
exports.command = 'gsp <command>'
exports.desc = 'Interact with a graph store'
exports.builder = function (yargs) {
    return yargs
        .commandDir('gsp')
        // .example('$0 file count doap.ttl', 'count the unique triple in the file doap.ttl')
        .epilog('All graph store commands try to login by using the following environment variables: RDFSH_TOKEN (preferred), RDFSH_USER + RDFSH_PASSWORD')
}
exports.handler = function (argv) {}
