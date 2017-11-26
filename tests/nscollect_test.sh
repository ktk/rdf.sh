#!/usr/bin/env bash

testNsCollect() {
    rm -f prefixes.ttl
    assertEquals "10 prefixes from 2 file(s) collected in prefixes.ttl (0 before)" "$(../rdf ns collect)"
    assertEquals "10 prefixes from 2 file(s) collected in prefixes.ttl (10 before)" "$(../rdf ns collect)"
    rm -f prefixes.ttl
}

testNsDist() {
    rm -f prefixes.ttl test.ttl
    touch test.ttl
    assertEquals "10 prefixes from 3 file(s) collected in prefixes.ttl (0 before)" "$(../rdf ns collect)"
    assertEquals "test.ttl: +10 prefix declarations" "$(../rdf ns distribute test.ttl)"
    assertEquals "test.ttl: +0 prefix declarations" "$(../rdf ns distribute test.ttl)"
    rm -f prefixes.ttl test.ttl
}
