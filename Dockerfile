FROM ubuntu:24.04 as installer

WORKDIR /installer

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    libaio-dev \
    build-essential \
    make \
    unzip \
    postgresql-server-dev-all \
    postgresql-common \
    wget

# download oracle instant client and sdk
RUN wget --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/2114000/instantclient-basic-linux.x64-21.14.0.0.0dbru.zip
RUN wget --no-check-certificate https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip

# extract the files
RUN unzip "*.zip" -d ./
RUN mkdir -p /usr/lib/oracle/21.14
RUN mv instantclient_21_14/* /usr/lib/oracle/21.14/

RUN touch /etc/ld.so.conf.d/oracle.conf
RUN touch /etc/profile.d/oracle.sh
RUN echo "export ORACLE_HOME=/usr/lib/oracle/21.14\nexport LD_LIBRARY_PATH=/usr/lib/oracle/21.14" > /etc/profile.d/oracle.sh
RUN echo "/usr/lib/oracle/21.14/" > /etc/ld.so.conf.d/oracle.conf

RUN export ORACLE_HOME=/usr/lib/oracle/21.14
RUN export LD_LIBRARY_PATH=/usr/lib/oracle/21.14
RUN ldconfig

# download the oracle_fdw source files
RUN wget --no-check-certificate https://github.com/laurenz/oracle_fdw/archive/refs/tags/ORACLE_FDW_2_6_0.zip
RUN unzip ORACLE_FDW_2_6_0.zip
# RUN cat /etc/ld.so.conf.d/oracle.conf; exit 1;
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/oracle/21.14
ENV ORACLE_HOME=/usr/lib/oracle/21.14
ENV LD_LIBRARY_PATH=/usr/lib/oracle/21.14
RUN cd oracle_fdw-ORACLE_FDW_2_6_0 && make && make install

FROM postgres:16.2


COPY --from=installer /usr/lib/oracle/21.14 /usr/lib/oracle/21.14
COPY --from=installer /etc/ld.so.conf.d/oracle.conf /etc/ld.so.conf.d/oracle.conf
COPY --from=installer /etc/profile.d/oracle.sh /etc/profile.d/oracle.sh
COPY --from=installer /usr/lib/postgresql/16/lib/oracle_fdw.so /usr/lib/postgresql/16/lib/oracle_fdw.so
COPY --from=installer /usr/share/postgresql/16/extension/oracle_fdw.control /usr/share/postgresql/16/extension/oracle_fdw.control
COPY --from=installer /usr/share/postgresql/16/extension/*.sql /usr/share/postgresql/16/extension/
COPY --from=installer /usr/share/doc/postgresql-doc-16/extension/README.oracle_fdw /usr/share/doc/postgresql-doc-16/extension/README.oracle_fdw

RUN echo "export ORACLE_HOME=/usr/lib/oracle/21.14" >> ~/.bashrc

RUN echo "export LD_LIBRARY_PATH=/usr/lib/oracle/21.14" >> ~/.bashrc

RUN echo "export PATH=/usr/lib/oracle/21.14:$PATH" >> ~/.bashrc

RUN ldconfig

RUN echo "CREATE EXTENSION oracle_fdw;" > /docker-entrypoint-initdb.d/01_oracle_fdw.sql

USER postgres