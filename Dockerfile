# Sphinx Search
#
# @version 	2.1.9
# Heavily customized from https://github.com/leodido/dockerfiles
FROM tianon/centos:latest

MAINTAINER CenturyLink

# add public key
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
# install utils
RUN yum install wget tar -y -q
# install sphinxsearch build dependencies
RUN yum install autoconf automake libtool gcc-c++ -y -q
# install sphinxsearch dependencies for odbc
RUN yum install unixODBC-devel -y -q
# install sphinxsearch dependencies for mysql support
RUN yum install mysql-devel -y -q
# install sphinxsearch dependencies for postgresql supp
RUN yum install postgresql-devel -y -q
# install sphinxsearch dependencies for xml support
RUN yum install expat-devel -y -q
# download libstemmer source and extract it
RUN wget -nv -O - http://snowball.tartarus.org/dist/libstemmer_c.tgz | tar zx
# download re2 source and extract it
RUN wget -nv -O - https://re2.googlecode.com/files/re2-20140304.tgz | tar zx
# download sphinxsearch source and extract it
RUN wget -nv -O - http://sphinxsearch.com/files/sphinx-2.1.9-release.tar.gz | tar zx
# copy libstemmer inside sphinxsearch source code
RUN cp -R libstemmer_c/* sphinx-2.1.9-release/libstemmer_c/
# copy libstemmer inside sphinxsearch source code
RUN cp -R re2/* sphinx-2.1.9-release/libre2/
# compile and install sphinxsearch
RUN cd sphinx-2.1.9-release && ./configure --enable-id64 --with-mysql --with-pgsql --with-libstemmer --with-libexpat --with-iconv --with-unixodbc --with-re2
# libstemmer changed the name of the non-UTF8 Hungarian source files,
# but the released version of sphinx still refers to it under the old name.
RUN cd sphinx-2.1.9-release && sed -i  s#stem_ISO_8859_1_hungarian#stem_ISO_8859_2_hungarian#g libstemmer_c/Makefile.in
RUN cd sphinx-2.1.9-release && make
RUN cd sphinx-2.1.9-release && make install
# remove sources
RUN rm -rf sphinx-2.1.9-release/ && rm -rf libstemmer_c/ && rm -rf re2/

# expose ports
EXPOSE 9312 9306

# prepare directories
RUN mkdir -p /var/idx/sphinx && \
    mkdir -p /var/log/sphinx && \
    mkdir -p /var/lib/sphinx && \
    mkdir -p /var/run/sphinx && \
    mkdir -p /var/diz/sphinx

# dicts
ADD dicts /var/diz/sphinx

# Expose some folders for configurations
VOLUME ["/var/idx/sphinx", "/var/log/sphinx", "/var/lib/sphinx", "/var/run/sphinx", "/var/diz/sphinx"]

# scripts
ADD searchd.sh /
RUN chmod a+x searchd.sh
ADD indexall.sh /
RUN chmod a+x indexall.sh

# run the script
CMD ["./indexall.sh"]
