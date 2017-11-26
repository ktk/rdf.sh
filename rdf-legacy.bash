#!/usr/bin/env bash
# @(#) A multi-tool shell script for doing Semantic Web jobs on the command line.
# shellcheck disable=SC1090

# Use the unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail; export FS=$'\n\t'

BASH_MAJOR_VERSION=$(echo "${BASH_VERSION}" | cut -d "." -f 1)
if [ "$BASH_MAJOR_VERSION" != "4" ]; then
    echo "Error: $(basename "${0}") needs a bash major version 4."
    exit 1
fi

# application metadata
name="rdf.sh"
version="0.8.0"
home="https://github.com/seebi/rdf.sh"

# basic application environment
this=$(basename "$0")
thisexec=$0
command="${1:-}"
os=$(uname -s | tr "[:upper:]" "[:lower:]")

# rdf.sh uses proper XDG config and cache directories now
if [ "${XDG_CONFIG_HOME:-}" == "" ]
then
    XDG_CONFIG_HOME="$HOME/.config"
fi
if [ "${XDG_CACHE_HOME:-}" == "" ]
then
    XDG_CACHE_HOME="$HOME/.cache"
fi
confdir="$XDG_CONFIG_HOME/rdf.sh"
cachedir="$XDG_CACHE_HOME/rdf.sh"
mkdir -p "$confdir"
mkdir -p "$cachedir"

configfile="$confdir/rc"
historyfile="$cachedir/resource.history"
prefixcache="$cachedir/prefix.cache"
prefixlocal="$confdir/prefix.local"
touch "$prefixlocal"
touch "$prefixcache"

# load config variables or create empty resource configuration
if [ -r "$configfile" ]
then
    # shellcheck disable=SC1090
    source "$configfile"
else
    touch "$configfile"
fi

# TODO: add and use -w %{http_code} for better error detection
if [ "${RDFSH_CURLOPTIONS_ADDITONS:-}" == "" ]
then
    curlcommand="curl -A ${name}/${version} -s -L"
else
    curlcommand="curl -A ${name}/${version} -s -L $RDFSH_CURLOPTIONS_ADDITONS"
fi

curlArgs=(-A "'$name/$version'" -s -L)

# Auth is done either by a given
# - an env token
# - OR user and pass env credentials
# - OR the the credentials are in the .netrc
if [ "${RDFSH_TOKEN:-}" != "" ]; then
    curlArgs+=(-H "'Authorization: Bearer ${RDFSH_TOKEN}'")
elif [ "${RDFSH_USER:-}" != "" ] && [ "${RDFSH_PASSWORD:-}" != "" ] ; then
    curlArgs+=(-u "'${RDFSH_USER}:${RDFSH_PASSWORD}'")
else
    curlArgs+=(--netrc-optional)
fi

if [ "${RDFSH_ACCEPT_HEADER:-}" == "" ]
then
    mimetypes="text/turtle; q=1.0, application/x-turtle; q=0.9, text/n3; q=0.8, application/rdf+xml; q=0.5, text/plain; q=0.1"
else
    mimetypes="$RDFSH_ACCEPT_HEADER"
fi

### mac workarounds
uname=$(uname)
if [ "$uname" == "Darwin" ]
then
    sedi="sed -i -E"
else
    sedi="sed -i"
fi


###
# private functions
###

# https://stackoverflow.com/questions/1527049
# Join elements of an array
_joinArrayBy() {
    local d=$1;
    shift;
    echo -n "$1";
    shift;
    printf "%s" "${@/#/$d}";
}

# https://stackoverflow.com/questions/38015239/
# urlencode a string
_urlencodepipe() {
    local LANG=C; local c;
    while IFS= read -r c; do
        case $c in [a-zA-Z0-9.~_-]) printf "%s" "$c"; continue ;; esac
        printf "%s" "$c" | od -An -tx1 | tr ' ' % | tr -d '\n'
    done <<EOF
$(fold -w1)
EOF
  echo
}
# use urlencodepipe and wrap it to a normal command
_urlencode() {
    printf "%s" "$*" | _urlencodepipe
}

# outputs a given input turtle file (highlighted or not)
_outputTurtle ()
{
    turtleFile=${1:-}
    if [ "$turtleFile" == "" ]
    then
        echo "_outputTurtle error: need an parameter"
        exit 1
    fi

    # check for actively suppressing the pygmentize highlighting
    if [ "${RDFSH_HIGHLIGHTING_SUPPRESS:-}" == "true" ]
    then
        cat "$turtleFile"
    else
        # if hightlight is enable, try to pipe it through pygmentize, otherwise just cat it
        if echo 'ttt'| pygmentize -l turtle 2>/dev/null >/dev/null; then
            pygmentize -l turtle "$turtleFile"
        else
            cat "$turtleFile"
        fi
    fi
}

# output the md5 sum of a given string
_md5sum ()
{
    local string md5sumexec

    string=${1:-}
    if [ "$string" == "" ]
    then
        echo "_md5sum error: need an parameter"
        exit 1
    fi

    if which md5 2>/dev/null >/dev/null; then
        md5sumexec="md5"
    else
        if which md5sum 2>/dev/null >/dev/null; then
            md5sumexec="md5sum"
        else
            echo "Error: you need 'md5' or 'md5sum' for this command."
            exit 1
        fi
    fi

    echo -n "$string" | $md5sumexec | cut -d " " -f 1
}

_cachePopulateFile ()
{
    local url file count cachefile

    url=${1:-}
    file=${2:-}
    if [ "$file" == "" ]
    then
        echo "_cachePopulateFile error: need two parameters $url and $file"
        exit 1
    fi

    if [ "${RDFSH_CACHE_POPULATE:-}" == "true" ];
    then
        count=$(wc -l "$file" | cut -d " " -f 1)
        if [ "$count" != 0 ]
        then
            cachefile=url-$(_md5sum "$url").nt
            cp "$file" "$cachedir/$cachefile"
        fi
    fi
}

_cacheGetPath ()
{
    local url cachefile

    url=${1:-}
    if [ "$url" == "" ]
    then
        echo "_cacheGetPath error: need one parameter"
        exit 1
    fi

    if [ "${RDFSH_CACHE_USE:-}" == "true" ];
    then
        cachefile=url-$(_md5sum "$url").nt
        if [ -r "$cachedir/$cachefile" ];
        then
            echo "$cachedir/$cachefile"
        fi
    else
        echo ""
    fi
}

# fetches an URL as ntriples and outputs it to stdout
# caches the fetched ntriples documents optionally
_httpGetNtriples ()
{
    local url tmpfile cachePath

    url=${1:-}
    if [ "$url" == "" ]
    then
        echo "_httpGetNtriples error: need an parameter"
        exit 1
    fi

    cachePath=$(_cacheGetPath "$url")
    if [ "$cachePath" != "" ];
    then
        # cache hit
        cat "$cachePath"
    else
        # cache miss
        tmpfile=$(_getTempFile)
        if [ "${RDFSH_HTTPGETNTRIPLES_COMMAND:-}" == "" ]
        then
            $curlcommand -H "Accept: $mimetypes" "$url" | rapper -q -i guess -o ntriples -I "$url" - 2>/dev/null >"$tmpfile" || true
        else
            $RDFSH_HTTPGETNTRIPLES_COMMAND "$url" 2>/dev/null >"$tmpfile" || true
        fi

        cat "$tmpfile"
        _cachePopulateFile "$url" "$tmpfile"
        rm -f "$tmpfile"
    fi
}

# takes an input command name and checks for availability
_checkTool ()
{
    local tool

    tool=${1:-}
    if [ "$tool" == "" ]
    then
        echo "checkTool error: need an parameter"
        exit 1
    fi

    for tool in "$@"
    do
        if ! which "$tool" 2>/dev/null >/dev/null; then
            echo "Error: the command line tool '$tool' is not available in your path."
            exit 1
        fi
    done
}

# takes an input string and checks if it is a valid qname
_isQName ()
{
    local qname LocalPart Prefix

    _checkTool cut

    qname=${1:-}
    if [ "$qname" == "" ]
    then
        echo "isQName error: need an parameter"
        exit 1
    fi

    LocalPart=$(echo "$qname" | cut -d ":" -f 2)
    if [ "$qname" == "$LocalPart" ]
    then
        echo "false"
        return
    else
        Prefix=$(echo "$qname" | cut -d ":" -f 1)

        # this is ugly ... here we distinguish between uris and qnames
        case "$Prefix" in
            "http" | "https" | "mailto" | "ldap" | "urn" )
                echo "false"
                return
            ;;
        esac

        if [ "$qname" != "$Prefix:$LocalPart" ]
        then
        echo "false"
        return
        else
            echo "true"
            return
        fi
    fi
}

# try to prepare the prefix definitions
_getFeatures()
{
    local file features namespaceCount prefix

    _checkTool grep

    file=${1:-}
    if [ "$file" == "" ]
    then
        echo "getFeatures error: need an parameter"
        exit 1
    fi

    #features='-f xmlns:foaf="http://xmlns.com/foaf/0.1/" -f xmlns:site="http://ns.ontowiki.net/SysOnt/Site/"'
    features=""
    # shellcheck disable=SC2013
    for namespace in $(cat "$prefixlocal" "$prefixcache" | grep "|" | grep -v "?" | cut -d "|" -f 2)
    do
        namespaceCount=$(grep -c -E "$namespace[^>]+\>" "$file")
        if [[ "$namespaceCount" -ge 1 ]]; then
            prefix=$(_getPrefixForNamespace "$namespace")
            features="$features -f xmlns:$prefix=\"$namespace\""
        fi
    done
    echo "$features"
}

# takes a qname and outputs the prefix
_getPrefix ()
{
    local qname LocalPart Prefix

    _checkTool cut

    qname=${1:-}
    if [ "$qname" == "" ]
    then
        echo "getPrefix error: need an qname parameter"
        exit 1
    fi

    LocalPart=$(echo "$qname" | cut -d ":" -f 2)
    if [ "$qname" == "$LocalPart" ]
    then
        echo "getPrefix error: $qname is not a valid qname"
        exit 1
    else
        Prefix=$(echo "$qname" | cut -d ":" -f 1)
        if [ "$qname" != "$Prefix:$LocalPart" ]
        then
            echo "getPrefix error: $qname is not a valid qname"
            exit 1
        else
            echo "$Prefix"
        fi
    fi
}

# takes a qname and outputs the LocalName
_getLocalName ()
{
    local qname LocalPart Prefix

    _checkTool cut

    qname=${1:-}
    if [ "$qname" == "" ]
    then
        echo "getLocalName error: need an qname parameter"
        exit 1
    fi

    LocalPart=$(echo "$qname" | cut -d ":" -f 2)
    if [ "$qname" == "$LocalPart" ]
    then
        echo "getLocalName error: $qname is not a valid qname"
        exit 1
    else
        Prefix=$(echo "$qname" | cut -d ":" -f 1)
        if [ "$qname" != "$Prefix:$LocalPart" ]
        then
        echo "getLocalName error: $qname is not a valid qname"
        exit 1
        else
            echo "$LocalPart"
        fi
    fi
}

# takes an input qname or URI and outputs the expanded full URI (if it is a qname)
_expandQName ()
{
    local input isQName prefix localName namespace

    input=${1:-}
    isQName=$(_isQName "$input")
    if [ "$isQName" == "true" ]
    then
        prefix=$(_getPrefix "$input")
        localName=$(_getLocalName "$input")
        namespace=$($thisexec ns "$prefix")
        echo "$namespace$localName"
    else
        echo "$input"
    fi
}

# takes a turtle file location and looks for missing prefix declarations
# outputs a prefix declaration list
# Note: currently, ALL cached and configured prefixes are listed
_getUndeclaredPrefixes ()
{
    local file namespace prefix

    file=${1:-}
    if [ "$file" == "" ]
    then
        echo "getUndeclaredPrefixes error: need a file location parameter"
        exit 1
    fi
    # shellcheck disable=SC2013
    for nsline in $(cat "$prefixlocal" "$prefixcache" | grep "|")
    do
        namespace=$(echo "$nsline" | cut -d "|" -f 2)
        prefix=$(echo "$nsline" | cut -d "|" -f 1)
        echo "@prefix $prefix: <$namespace> ."
    done
}

_getNamespaceFromPrefix ()
{
    local prefix namespace

    _checkTool curl cut

    prefix=${1:-}
    if [ "$prefix" == "" ]
    then
        echo "getNamespaceFromPrefix error: need a prefix parameter"
        exit 1
    fi
    namespace=$(_getNamespaceForPrefix "$prefix")
    if [ "$namespace" == "" ]
    then
        # no cache-hit, request it from prefix.cc
        namespace=$($curlcommand "http://prefix.cc/$prefix.file.n3" | cut -d "<" -f 2 | cut -d ">" -f 1)
        if [ "$namespace" != "" ]
        then
            _addPrefixToCache "$prefix" "$namespace"
        fi
    fi
    # output cache hit or curl output (maybe empty)
    echo "$namespace"
}

# give a namespace and get a prefix or it
# this function search in the cache as well the locally configured prefixes
_getPrefixForNamespace ()
{
    local namespace prefix

    _checkTool cat grep head cut

    namespace=${1:-}
    if [ "$namespace" == "" ]
    then
        echo "getPrefixFromCache error: need a namespace parameter"
        exit 1
    fi
    prefix=$(cat "$prefixlocal" "$prefixcache" | grep "$namespace" | head -1 | cut -d "|" -f 1)
    echo "$prefix"
}

# give a prefix and get a namespace or ""
# this function search in the cache as well the locally configured prefixes
_getNamespaceForPrefix ()
{
    local prefix namespace

    _checkTool cat grep head cut

    prefix=${1:-}
    if [ "$prefix" == "" ]
    then
        echo "getPrefixFromCache error: need a prefix parameter"
        exit 1
    fi
    namespace=$(cat "$prefixlocal" "$prefixcache" | grep "^$prefix|" | head -1 | cut -d "|" -f 2)
    echo "$namespace"
}

# calculate a color for a resource URI (http://cold.aksw.org)
_getColorForResource()
{
    local uri

    _checkTool cut

    uri=${1:-}
    if [ "$uri" == "" ]
    then
        echo "getColorForResource error: need a resource parameter"
        exit 1
    fi

    echo "#$(_md5sum "$uri" | cut -c 27-)"
}

# give a prefix + namespace and get a new cache entry
_addPrefixToCache ()
{
    local prefix namespace existingNamespace

    prefix=${1:-}
    if [ "$prefix" == "" ]
    then
        echo "addPrefixToCache error: need a prefix parameter"
        exit 1
    fi
    namespace=${2:-}
    if [ "$namespace" == "" ]
    then
        echo "addPrefixToCache error: need a namespace parameter"
        exit 1
    fi
    touch "$prefixcache"
    existingNamespace=$(_getNamespaceForPrefix "$prefix")
    if [ "$existingNamespace" == "" ]
    then
        echo "$prefix|$namespace" >>"$prefixcache"
    fi
}

# add a resource to the .resource_history file
_addToHistory ()
{
    local resource historyfile count

    _checkTool grep wc sed

    resource=${1:-}
    if [ "$resource" == "" ]
    then
        echo "addToHistory error: need an resource parameter"
        exit 1
    fi

    historyfile=${2:-}
    if [ "$historyfile" == "" ]
    then
        echo "addToHistory error: need an historyfile as second parameter "
        exit 1
    fi
    touch "$historyfile"

    count=$(grep -c "$resource" "$historyfile" || true)
    if [ "$count" != 0 ]
    then
        # f resource exists, remove it
        $sedi "s|$resource||g" "$historyfile"
        $sedi '/^$/d' "$historyfile"
    fi
    # add (or re-add) the resource at the end
    echo "$resource" >>"$historyfile"
}

# creates a tempfile and returns the filename
_getTempFile ()
{
    local tmpfile

    _checkTool mktemp

    tmpfile=$(mktemp -q ./rdfsh-XXXX)
    mv "$tmpfile" "$tmpfile.tmp"
    echo "$tmpfile.tmp"
}


###
# the "command" functions:
# the are executed by using the first parameter and get all parameters as options
###

docu_ns () { echo "curls the namespace from prefix.cc"; }
do_ns ()
{
    local prefix suffix namespace

    _checkTool curl

    prefix="${2:-}"
    suffix="${3:-}"
    if [ "$prefix" == "" ]
    then
        echo "Syntax:" "$this" "$command <prefix> <suffix>"
        echo "($(docu_ns))"
        echo " suffix can be n3, rdfa, sparql, ...)"
        exit 1
    fi
    if [ "$suffix" == "" ]
    then
        # this is a standard request as "rdf ns foaf"
        namespace=$(_getNamespaceFromPrefix "$prefix")
        echo "$namespace"
    else
        if [ "$suffix" == "plain" ]
        then
            # this is for vim integration, plain = without newline
            namespace=$(_getNamespaceFromPrefix "$prefix")
            echo -n "$namespace"
        else
            # if a real suffix is given, we always fetch from prefix.cc
            $curlcommand "http://prefix.cc/$prefix.file.$suffix"
        fi
    fi
}

docu_edit () { echo "edit the content of an existing linked data resource via LDP (GET + PUT)";}
do_edit ()
{
    local uri doEditTmpfile features addedPrefixDeclarations

    _checkTool curl rapper rm cp

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_edit))"
        exit 1
    fi
    uri=$(_expandQName "$uri")
    doEditTmpfile=$(_getTempFile)

    _httpGetNtriples "$uri" >"${doEditTmpfile}"
    features=$(_getFeatures "${doEditTmpfile}")
    # shellcheck disable=SC2086
    rapper -q ${features} -i ntriples -o turtle -I "$uri" "${doEditTmpfile}" >"${doEditTmpfile}.ttl" || true
    $EDITOR "$doEditTmpfile.ttl"

    # look for missing prefixes and add them at the beginning
    addedPrefixDeclarations=$(_getUndeclaredPrefixes "$doEditTmpfile.ttl")
    echo "$addedPrefixDeclarations" >"$doEditTmpfile.ttl.tmp"
    cat "$doEditTmpfile.ttl" >>"$doEditTmpfile.ttl.tmp"
    mv "$doEditTmpfile.ttl.tmp" "$doEditTmpfile.ttl"

    # put the new resource
    $thisexec put "$uri" "$doEditTmpfile.ttl"

    # clean up
    rm "$doEditTmpfile" "$doEditTmpfile.ttl"

    # add history
    _addToHistory "$uri" "$historyfile"
}

docu_put () { echo "replaces an existing linked data resource via LDP";}
do_put ()
{
    local uri filename

    _checkTool curl

    uri="${2:-}"
    filename="${3:-}"
    if [ "$filename" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart> <path/to/your/file.rdf>"
        echo "($(docu_put))"
        exit 1
    fi
    uri=$(_expandQName "$uri")

    # perform the HTTP request
    $curlcommand -X PUT "$uri" --data "@$filename" -H "Content-Type:text/turtle"

    # add history
    _addToHistory "$uri" "$historyfile"
}

docu_delete () { echo "deletes an existing linked data resource via LDP";}
do_delete ()
{
    local uri

    _checkTool curl

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_delete))"
        exit 1
    fi
    uri=$(_expandQName "$uri")
    $curlcommand -X DELETE "$uri"
    _addToHistory "$uri" "$historyfile"
}

docu_desc () { echo "outputs description of the given resource in a given format (default: turtle)";}
do_desc ()
{
    local uri output tmpfile

    _checkTool curl mv cat grep cut wc roqet rapper rm

    uri="${2:-}"
    output="${3:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart> <format>"
        echo "($(docu_desc))"
        exit 1
    fi
    if [ "$output" == "" ]
    then
        output="turtle"
    fi
    uri=$(_expandQName "$uri")
    tmpfile=$(_getTempFile)
    _httpGetNtriples "$uri" >"$tmpfile"

    # fetches only triples with URI as subject (output is turtle)
    roqet -q -e "CONSTRUCT {<$uri> ?p ?o} WHERE {<$uri> ?p ?o}" -D "$tmpfile" >"$tmpfile.out" 2>/dev/null || true

    # reformat and output turtle file
    $thisexec turtleize "$tmpfile.out" >"$tmpfile.ttl"
    _outputTurtle "$tmpfile.ttl"

    # clean up
    rm -f "$tmpfile" "$tmpfile.out" "$tmpfile.ttl"

    # add history
    _addToHistory "$uri" "$historyfile"
}

docu_list () { echo "list resources which start with the given URI"; }
do_list ()
{
    local uri tmpfile

    _checkTool roqet cut grep rm

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_list))"
        exit 1
    fi
    uri=$(_expandQName "$uri")
    tmpfile=$(_getTempFile)
    _httpGetNtriples "$uri" >"$tmpfile.nt"
    roqet -q -e "SELECT DISTINCT ?s WHERE {?s ?p ?o. FILTER isURI(?s) } " -D "$tmpfile.nt" 2>/dev/null | cut -d "<" -f 2 | cut -d ">" -f 1 | grep "$uri" || true
    rm -f "$tmpfile" "$tmpfile.nt"
}

docu_get () { echo "fetches an URL as RDF to stdout (tries accept header)"; }
do_get ()
{
    local uri tmpfile

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_get))"
        exit 1
    fi

    uri=$(_expandQName "$uri")
    tmpfile=$(_getTempFile)
    _httpGetNtriples "$uri" >"$tmpfile.nt"
    $thisexec turtleize "$tmpfile.nt"
    rm "$tmpfile" "$tmpfile.nt"
    _addToHistory "$uri" "$historyfile"
}

docu_get-ntriples () { echo "curls rdf and transforms to ntriples"; }
do_get-ntriples ()
{
    local uri

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_get-ntriples))"
        exit 1
    fi

    uri=$(_expandQName "$uri")
    _httpGetNtriples "$uri"
    _addToHistory "$uri" "$historyfile"
}

docu_headn () { echo "curls only the http header"; }
do_headn ()
{
    local uri

    _checkTool curl

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_head))"
        exit 1
    fi

    uri=$(_expandQName "$uri")
    $curlcommand -I -X HEAD "$uri"
    _addToHistory "$uri" "$historyfile"
}

docu_head () { echo "curls only the http header but accepts only rdf"; }
do_head ()
{
    local uri

    _checkTool curl

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <URI | Prefix:LocalPart>"
        echo "($(docu_rdfhead))"
        exit 1
    fi

    uri=$(_expandQName "$uri")
    $curlcommand -I -X HEAD -H "Accept: $mimetypes" "$uri"
    _addToHistory "$uri" "$historyfile"
}

docu_diff () { echo "diff of all triples from two RDF files"; }
do_diff ()
{
    local source1 source2 difftool RDFSHDIFF dest1 dest2

    _checkTool rapper rm sort

    source1="${2:-}"
    source2="${3:-}"
    difftool="${4:-}"

    if [ "$difftool" != "" ]
    then
        RDFSHDIFF=$difftool
    else
        _checkTool diff
        RDFSHDIFF="diff"
    fi

    if [ "$source2" == "" ]
    then
        echo "Syntax:" "$this" "$command <rdf-file-1> <rdf-file-2>"
        echo "($(docu_diff))"
        exit 1
    fi
    dest1="/tmp/$RANDOM-$(basename "$source1")"
    dest2="/tmp/$RANDOM-$(basename "$source2")"
    rapper -i guess "$source1" 2> /dev/null | sort -u >"$dest1" || true
    rapper -i guess "$source2" 2> /dev/null | sort -u >"$dest2" || true
    $RDFSHDIFF "$dest1" "$dest2" || true
    rm -f "$dest1" "$dest2"
}

docu_color () { echo "get a html color for a resource URI"; }
do_color ()
{
    local uri

    uri="${2:-}"
    if [ "$uri" == "" ]
    then
        echo "Syntax:" "$this" "$command <uri>"
        echo "($(docu_color))"
        exit 1
    fi

    _getColorForResource "$uri"
}

docu_count () { echo "count distinct triples"; }
do_count ()
{
    local file tmpfile count

    _checkTool rapper wc sort

    file="${2:-}"
    if [ "$file" == "" ]
    then
        echo "Syntax:" "$this" "$command <file>"
        echo "($(docu_count))"
        exit 1
    fi
    tmpfile="/tmp/$RANDOM-$(basename "$file")"
    rapper -i guess "$file" 2>/dev/null | sort -u >"$tmpfile" || true
    count=$(wc -l <"$tmpfile")
    echo "$count"
    rm "$tmpfile"
}

docu_split () { echo "split an RDF file into pieces of max X triple and outputs the piece filenames"; }
do_split ()
{
    local file size tmpdir

    _checkTool rapper split wc find

    file="${2:-}"
    size="${3:-}"
    if [ "$file" == "" ]
    then
        echo "Syntax:" "$this" "$command <file> <size-X> <command>"
        echo "($(docu_split))"
        exit 1
    fi
    if [ "$size" == "" ]
    then
        size="25000"
    fi

    tmpdir=$(mktemp -d)
    rapper -i guess -q "$file" | split -a 5 -l $size - "$tmpdir/" || true
    find "$tmpdir" -type f
}

docu_nscollect() { echo "collects prefix declarations of a list of ttl/n3 files";}
do_nscollect()
{
    local prefixfile countBefore count
    local -a files

    _checkTool cat wc grep sort

    prefixfile="${2:-}"

    if [ "$prefixfile" == "" ]
    then
        prefixfile="prefixes.ttl"
    fi

    if [ -f "$prefixfile" ]
    then
        countBefore=$(wc -l < $prefixfile)
    else
        countBefore=0
    fi

    files=($(find . -name "*.ttl" | grep -v $prefixfile))
    rm -f "$prefixfile"
    for file in "${files[@]}"
    do
        grep "@prefix " < "$file" >> "$prefixfile" || true
    done
    sort -u "$prefixfile" > "$prefixfile.new"
    mv "$prefixfile.new" "$prefixfile"
    count=$(wc -l < "$prefixfile")
    echo "$count prefixes from ${#files[@]} file(s) collected in $prefixfile ($countBefore before)"
}

docu_nsdist () { echo "distributes prefix declarations from one file to a list of other ttl/n3 files";}
do_nsdist ()
{
    local prefixfile count tmpfile before after result
    local -a files

    _checkTool grep mktemp wc

    prefixfile="prefixes.ttl"
    if [ ! -f "$prefixfile" ]
    then
        echo "Syntax:" "$this" "$command <targetfiles>"
        echo "($(docu_nsdist))"
        echo "I try to use $prefixfile as source but it is empty."
        exit 1
    fi

    if [ "${2:-}" == "" ]
    then
        files=($(find . -name "*.ttl" | grep -v $prefixfile))
    else
        files=($@)
    fi

    count=$(wc -l < "$prefixfile")
    tmpfile=$(_getTempFile)
    for target in "${files[@]}"
    do
        if [ -f "$target" ]
        then
            # shellcheck disable=SC2126
            before=$(grep "@prefix " < "$target" | wc -l || echo 0)
            grep -v "@prefix " < "$target" >"$tmpfile" || true
            cat $prefixfile >"$target"
            cat "$tmpfile" >>"$target"
            # shellcheck disable=SC2126
            after=$(grep "@prefix " < "$target" | wc -l || echo 0)
            let result=$after-$before || true
            if [ "$result" -ge "0" ]
            then
                echo "$target: +$result prefix declarations"
            else
                echo "$target: $result prefix declarations"
            fi
        fi
    done
    rm "$tmpfile"
}

docu_turtleize() { echo "outputs an RDF file in turtle, using as much as possible prefix declarations"; }
do_turtleize ()
{
    local file features

    _checkTool rapper

    file="${2:-}"
    if [ "$file" == "" ]
    then
        echo "Syntax:" "$this" "$command <file>"
        echo "($(docu_turtleize))"
        exit 1
    fi

    features=$(_getFeatures "$file")
    # shellcheck disable=SC2086
    rapper -q ${features} -i guess -o turtle "$file" 2>/dev/null || true
}

docu_skolemize() { echo "Not a real skolemization but materialises bnodes as IRIs and outputs the file turtleized. The second parameter is an optional namespace IRI."; }
do_skolemize ()
{
    local file domain seed

    _checkTool rapper uuid grep awk sort

    file="${2:-}"
    if [ "$file" == "" ]
    then
        echo "Syntax:" "$this" "$command <file>"
        echo "($(docu_skolemize))"
        exit 1
    fi

    domain="${3:-}"
    if [ "$domain" == "" ]
    then
        domain="urn:uuid:"
    else
        domain=$(_expandQName "$domain")
    fi

    tmpInput="/tmp/$RANDOM-$(basename "$file")"
    tmpOutput="/tmp/$RANDOM-$(basename "$file")"
    rapper -i guess "$file" 2>/dev/null | sort -u >"$tmpInput" || true

    # in order to have stable uuids with the same file, change seed to md5sum of the file
    seed="$tmpInput/"
    awk -v domain="$domain" -v seed="$seed" '
        BEGIN{FS=" "; OFS=" "; ORS=""}
        {
            subject=$1
            predicate=$2
            object=$3
            if (subject ~ /^_:genid[0-9]+$/) {
                cmd="uuid -v5 ns:URL " domain seed subject
                cmd |& getline subject
                close(cmd)
                subject = "<" domain subject ">"
            }
            print subject

            if (predicate ~ /^_:genid[0-9]+$/) {
                cmd="uuid -v5 ns:URL " domain seed predicate
                cmd |& getline predicate
                close(cmd)
                predicate = "<" domain predicate ">"
            }
            print " " predicate

            if (object ~ /^_:genid[0-9]+$/) {
                cmd="uuid -v5 ns:URL " domain seed object
                cmd |& getline object
                close(cmd)
                object = "<" domain object ">"
                print " " object " .\n"
            } else {
                for (i=3; i<=NF; ++i) print " " $i
                print "\n"
            }
        }' < "$tmpInput" > "$tmpOutput"

    $thisexec turtleize "$tmpOutput"
    rm -f "$tmpInput" "$tmpOutput"
}

docu_gsp-put() { echo "delete and re-create a graph via SPARQL 1.1 Graph Store HTTP Protocol"; }
do_gsp-put ()
{
    local sourceFile graphUri storeUrl args

    graphUri="${2:-}"
    sourceFile="${3:-}"
    if [ "$sourceFile" == "" ]
    then
        echo "Syntax:" "$this" "$command <graph URI | Prefix:LocalPart> <path/to/your/file.rdf> <store URL | Prefix:LocalPart (optional)>"
        echo "($(docu_gsp-put))"
        exit 1
    fi
    if [ ! -f "$sourceFile" ]
    then
        echo "Error:" "$sourceFile" "does not exist or is not readable."
        exit 1
    fi
    graphUri=$(_expandQName "$graphUri")

    args=("${curlArgs[@]}")
    args+=(-X PUT)
    args+=(-H "'Content-Type:text/turtle'")
    storeUrl="${4:-}"
    if [ "$storeUrl" == "" ]
    then
        # try to get $graphUri (direct graph identification)
        storeUrl="$graphUri"
    else
        # try to get $graphUri via $storeUrl (indirect graph identification)
        storeUrl=$(_expandQName "$storeUrl")
        encodedGraphUri=$(_urlencode "$graphUri")
        storeUrl="$storeUrl?graph=$encodedGraphUri"
    fi
    args+=(--data-binary @$sourceFile "$storeUrl")
    # TODO: try to avoid eval
    output=$(eval curl "${args[*]}")
    if [ "$output" == "" ]
    then
        echo "200 OK"
    else
        echo "$output"
    fi
}

docu_gsp-delete() { echo "delete a graph via SPARQL 1.1 Graph Store HTTP Protocol"; }
do_gsp-delete ()
{
    local graphUri storeUrl args

    graphUri="${2:-}"
    if [ "$graphUri" == "" ]
    then
        echo "Syntax:" "$this" "$command <graph URI | Prefix:LocalPart> <store URL | Prefix:LocalPart (optional)>"
        echo "($(docu_gsp-delete))"
        exit 1
    fi
    graphUri=$(_expandQName "$graphUri")

    args=("${curlArgs[@]}")
    args+=(-X DELETE)
    storeUrl="${3:-}"
    if [ "$storeUrl" == "" ]
    then
        # try to get $graphUri (direct graph identification)
        storeUrl="$graphUri"
        args+=("$storeUrl")
    else
        # try to get $graphUri via $storeUrl (indirect graph identification)
        storeUrl=$(_expandQName "$storeUrl")
        args+=(-G --data-urlencode "'graph=$graphUri'" "$storeUrl")
    fi
    # TODO: try to avoid eval
    output=$(eval curl "${args[*]}")
    if [ "$output" == "" ]
    then
        echo "200 OK"
    else
        echo "$output"
    fi
}

docu_gsp-get() { echo "get a graph via SPARQL 1.1 Graph Store HTTP Protocol"; }
do_gsp-get ()
{
    local graphUri storeUrl args

    graphUri="${2:-}"
    if [ "$graphUri" == "" ]
    then
        echo "Syntax:" "$this" "$command <graph URI | Prefix:LocalPart> <store URL | Prefix:LocalPart (optional)>"
        echo "($(docu_gsp-get))"
        exit 1
    fi
    graphUri=$(_expandQName "$graphUri")

    args=("${curlArgs[@]}")
    args+=(-G)
    storeUrl="${3:-}"
    if [ "$storeUrl" == "" ]
    then
        # try to get $graphUri (direct graph identification)
        storeUrl="$graphUri"
        args+=("$storeUrl")
    else
        # try to get $graphUri via $storeUrl (indirect graph identification)
        args+=(--data-urlencode "'graph=$graphUri'" "$storeUrl")
    fi
    # TODO: try to avoid eval
    eval curl "${args[*]}"
}

docu_help () { echo "outputs the manpage of $this"; }
do_help ()
{
    local realfile execdir manpage scriptdir

    _checkTool man

    realfile=$(readlink "$thisexec")
    if [ "$realfile" == "" ]
    then
        # assume useage over "xxx/yyy/rdf.sh/rdf.sh help"
        execdir=$(dirname "$thisexec")
        manpage="$execdir/rdf.1"
    else
        # assume rdf.sh started as link and manpage is in same dir with script
        execdir=$(dirname "$thisexec")
        scriptdir=$(dirname "$realfile")
        manpage="$execdir/$scriptdir/rdf.1"
    fi
    # try central manpage first, then try the guessed one
    if [[ "$os" == "darwin" ]]; then
        man rdf 2>/dev/null || man "$manpage"
    else
        man rdf 2>/dev/null || man -l "$manpage"
    fi
}

###
# execute the command NOW :-)
###


# taken from http://stackoverflow.com/questions/2630812/
commandlist=$(typeset -f | grep "do_.*()" | cut -d "_" -f 2 | cut -d " " -f 1 | sort)

# if no command is given, present a basic help screen
if [ "$command" == "" ]
then
    echo "$this is a a multi-tool shell script for doing Semantic Web jobs on the command line."
    echo "Version:  $version"
    echo "Homepage: $home"
    echo ""
    echo "Syntax: $this <command>"
    echo ""
    echo "Available commands are:"
    for cmd in $commandlist
    do
        echo "  $cmd:" "$(docu_"$cmd")"
    done
    exit 1
fi

# for generating the autocompletion suggestions automatically
if [ "$command" == "zshcomp" ]
then
    #echo "$commandlist"
    echo "("
    for cmd in $commandlist
    do
        echo "$cmd:\"$(docu_"$cmd")\""
    done
    echo ")"
    exit 1
fi

# now start the sub - command
# taken from http://stackoverflow.com/questions/1007538/
if type "do_$command" >/dev/null 2>&1
then
    "do_$command" "$@"
else
    echo "$this: '$command' is not a rdf command. See '$this help'."
    exit 1
fi
