#!/usr/bin/env bash

testCountLocalFile() {
    assertEquals "12" "$(../rdf file count foafPerson.nt)"
}

testCountRemoteResource() {
    assertEquals "58" "$(../rdf file count https://sebastian.tramp.name)"
}

