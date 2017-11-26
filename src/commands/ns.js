
exports.command = 'ns <command>'
exports.desc = 'work with namespaces'
exports.builder = function (yargs) {
    return yargs
        .commandDir('ns')
        .example('$0 ns lookup foaf', 'Get the typical namespace for the foaf prefix from prefix.cc or from the cache')
        .epilog('Fetched namespaces are cached and not fetched again. In addition to that, a prefix.local file is queried for local namespaces.')
}
exports.handler = function (argv) {}
