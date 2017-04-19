# mysql-surface-schema
bash script pulling mysql tables and column names, output in yml

#### from the --help display
usage: mysql_surface-schema-to-yml.sh  [-h | --help]  [ U=[mysql-user] ]  [ p=[mysql-password] ]  [ D=[mysql-database] ]  [ H=[mysql-host] ]  [ P=[mysql-port] ]

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
    MYSQL_PASSWORD=$PW ./mysql_surface-schema-to-yml.sh U=user D=db H=localhost P=3306
    unset PW
