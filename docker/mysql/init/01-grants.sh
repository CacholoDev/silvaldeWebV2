#!/bin/bash
# Grants the application user privileges to create and manage any
# database, including the *_test sibling created by `bin/rails db:create`.
# Runs once, on the first boot of a fresh MySQL volume.
set -euo pipefail

: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
