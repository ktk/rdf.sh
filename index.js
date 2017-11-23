#!/usr/bin/env node

const yargs = require('yargs');

var argv = yargs
  .commandDir('src/commands')
  .count('verbose')
  .alias('v', 'verbose')
  .demandCommand()
  .example('$0 ns skos', 'Get the typical namespace for the skos prefix')
  .help()
  .wrap(72)
  .argv
