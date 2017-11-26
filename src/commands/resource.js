
exports.command = 'resource <command>'
exports.desc = 'work with resources'
exports.builder = function (yargs) {
    return yargs
        .commandDir('resource')
        .example('$0 resource list skos:', 'List all subject in the SKOS namespace')
        .example('$0 resource desc foaf:Person', 'Describe the Person concept in the FOAF vocabulary')
        .epilog('Fetched resource are cached and not fetched again.')
}
exports.handler = function (argv) {}
