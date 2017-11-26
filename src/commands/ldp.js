
exports.command = 'ldp <command>'
exports.desc = 'Interact with a linked data platform'
exports.builder = function (yargs) {
  return yargs.commandDir('ldp')
}
exports.handler = function (argv) {}
