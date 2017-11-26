#!/usr/bin/env bash

testSkolemizeLocalFile() {
    sourceFile="skolemize-source.ttl"
    targetFile="skolemize-target.ttl"
    ../rdf file skolemize "$sourceFile" >"$targetFile"
    assertEquals "$(../rdf file count ${sourceFile})" "$(../rdf file count ${targetFile})"
    rm -f "$targetFile"
}
