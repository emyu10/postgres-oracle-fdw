# Oracle Foreign Data Wrapper for Postgres

Built from github.com/laurenz/oracle_fdw

For documentation and known issues, please refer to http://laurenz.github.io/oracle_fdw

## How to use this image
This is a postgres server. So just pull the image and run it.

```bash
docker pull emyu10/postgres-oracle-fdw
docker run --name postgres -p 5432:5432 emyu10/postgres-oracle-fdw
```

After running, check if the extension is enabled. If not just run
```CREATE EXTENSION oracle_fdw;``` in psql