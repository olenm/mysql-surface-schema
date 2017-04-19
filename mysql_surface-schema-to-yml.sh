#!/usr/bin/env bash

function help() {
cat <<EOF
usage: ${0##*/}  [ U=[mysql-user] ]  [ p=[mysql-password] ]  [ D=[mysql-database] ]  [ H=[mysql-host] ]  [ P=[mysql-port] ]

  Creates a yml friendly database 'schema' (ordered alphabetically) where only details are table and column names.
  > Parameter order does not matter, but is case sensitive

  Env Vars (params take precedence):
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
    MYSQL_PASSWORD=\$PW ./mysql_surface-schema-to-yml.sh U=user D=db H=localhost P=3306
    unset PW
EOF
}

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
for ((i=0; i< ${#args[@]}; i++)); do
  if [[ "${args[$i]:0:2}" == "U=" ]]; then
    UN="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "p=" ]]; then
    PW="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "D=" ]]; then
    DB="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "H=" ]]; then
    HN="${args[$i]:2}"
  fi
  if [[ "${args[$i]:0:2}" == "P=" ]]; then
    HP="${args[$i]:2}"
  fi
done

[[ -z "$UN" ]] && UN=${MYSQL_USER}
[[ -z "$PW" ]] && PW=${MYSQL_PASSWORD}
[[ -z "$DB" ]] && DB=${MYSQL_DATABASE-mysql}
[[ -z "$HN" ]] && HN=${MYSQL_HOST-localhost}
[[ -z "$HP" ]] && HP=${MYSQL_HOST-3306}




function sqlexec() {
    RES=$(mysql -u${UN} -p${PW} ${DB} -h ${HN} -P${HP} -Nse "${@}" 2>/dev/null)
    if [[ 0 -ne $? ]]; then
        echo "mysql -u${UN} -p<censored> ${DB} -h ${HN} -P${HP} -Nse  "
        echo "   '${@}'"
        exit 1
    fi
    echo "$RES" | sort -u
}


TABLES=$(sqlexec "show tables;" )
err_chk $? "${TABLES}"

echo "---"
for T in $TABLES; do
    echo "${T}:"
    RES=$(sqlexec "show columns from ${T};")
    err_chk $? "${RES}"
    echo "${RES}" | awk '{print "  - "$1}'
done

