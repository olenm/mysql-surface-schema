#!/usr/bin/env bash

function help() {
cat <<EOF
usage: ${0##*/}  [ U=[mysql-user] ]  [ p=[mysql-password] ]  [ D=[mysql-database] ]  [ H=[mysql-host] ]  [ P=[mysql-port] ] [ --mode=[yml|anything] ]

  Creates a yml friendly database 'schema' (ordered alphabetically) where only details are table and column names.
  > Parameter order does not matter, but is case sensitive

  Env Vars (params take precedence, even over .myncf):
    MYSQL_USER
    MYSQL_PASSWORD
    MYSQL_DATABASE
    MYSQL_HOST
    MYSQL_PORT

  Requirements:
    awk
    bash 4+
    mysql

  example:
    read -s PW
    MYSQL_PASSWORD=\$PW ./mysql_surface-schema-to-yml.sh U=user D=db H=localhost P=3306 --mode=yml
    unset PW
EOF
}

FILTER_ERR='Using a password on the command line interface can be insecure'

function err_chk() {
    if [[ 0 -ne $1 ]]; then
    echo -e "ERROR:\n $2" >&2
    echo "" >&2
    help >&2
    exit 1
fi

}

# regex arguments for combinations of --help (help, -h, ect)
for x in ${@}; do 
  if [[ "${x,,}" =~ ^(-+h(elp)?|-*help)$ ]]; then
    help
    exit 0
  fi
done

args=(${@})
MODE=""
for ((i=0; i< ${#args[@]}; i++)); do
  if [[ "${args[$i]:0:2}" == "U=" ]]; then
    tUN="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "p=" ]]; then
    tPW="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "D=" ]]; then
    DB="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "H=" ]]; then
    tHN="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "P=" ]]; then
    tHP="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:7}" == "--mode=" ]]; then
    MODE="${args[$i]:7}"
  fi
done


[[ -z "$tUN" ]] && tUN=${MYSQL_USER}
[[ -z "$tPW" ]] && tPW=${MYSQL_PASSWORD}
[[ -z "$DB" ]] && DB=${MYSQL_DATABASE}
[[ -z "$tHN" ]] && tHN=${MYSQL_HOST}
[[ -z "$tHP" ]] && tHP=${MYSQL_PORT}

[[ -n "$tUN" ]] && UN="-u${tUN}"
[[ -n "$tPW" ]] && PW="-p${tPW}"
# no DB alterations
[[ -n "$tHN" ]] && HN="-h ${tHN}"
[[ -n "$tHP" ]] && HP="-P${tHP}"

function sqlexec() {
    RES=$( mysql ${UN} ${PW} ${DB} ${HN} ${HP} -Nse "${@}"  2> >( awk "! /${FILTER_ERR}/")  )
    if [[ 0 -ne $? ]]; then
        echo "mysql ${UN} ${DB} ${HN} ${HP} -Nse  "
        echo "   '${@}'"
        exit 1
    fi
    echo "$RES" | sort -u
}

TABLES=$(sqlexec "show tables;" )
err_chk $? "${TABLES}"

if [[ "$MODE" == "yml" ]]; then
  echo "---"
  for T in $TABLES; do
    echo "${T}:"
    RES=$(sqlexec "show columns from ${T};")
    err_chk $? "${RES}"
    echo "${RES}" | awk '{print "  - "$1}'
  done
else
  for T in $TABLES; do
    RES=$(sqlexec "show columns from ${T};")
    err_chk $? "${RES}"
    echo "${RES}" | awk '{print $1}' | sed "s/^/$T./g"
  done
fi
