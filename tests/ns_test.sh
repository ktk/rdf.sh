#!/usr/bin/env bash

testSomeValidNamespaces()   {
    assertEquals "http://www.w3.org/1999/02/22-rdf-syntax-ns#" "$(../rdf ns lookup rdf)"
    assertEquals "http://www.w3.org/2000/01/rdf-schema#"       "$(../rdf ns lookup rdfs)"
    assertEquals "http://www.w3.org/2002/07/owl#"              "$(../rdf ns lookup owl)"
    assertEquals "http://purl.org/dc/elements/1.1/"            "$(../rdf ns lookup dc)"
    assertEquals "http://purl.org/dc/terms/"                   "$(../rdf ns lookup dct)"
}

