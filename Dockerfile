FROM httpd:2.4.34-alpine

ENV AWSTATS_VERSION 7.7-r0

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \ 
    && echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    && apk add --no-cache awstats=${AWSTATS_VERSION} gettext \
    && apk add --no-cache apache2-mod-perl curl gzip make \
    && echo 'Include conf/awstats_httpd.conf' >> /usr/local/apache2/conf/httpd.conf

RUN mkdir -p /opt/GeoIP \
    && curl -L https://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz \
        | gunzip -c - > /opt/GeoIP/GeoIP.dat \
    && curl -L https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
        | gunzip -c - > /opt/GeoIP/GeoLiteCity.dat

RUN curl -L http://xrl.us/cpanm > /bin/cpanm && chmod +x /bin/cpanm
RUN cpanm --no-wget Geo::IP::PurePerl \
    && cpanm --no-wget Geo::IP

ADD awstats_env.conf /etc/awstats/
ADD awstats_httpd.conf /usr/local/apache2/conf/
ADD entrypoint.sh /usr/local/bin/

ENV AWSTATS_CONF_LOGFILE "/var/local/log/access.log"
ENV AWSTATS_CONF_LOGFORMAT "%host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot"
ENV AWSTATS_CONF_SITEDOMAIN "my_website"
ENV AWSTATS_CONF_HOSTALIASES "localhost 127.0.0.1 REGEX[^.*$]"
ENV AWSTATS_CONF_SKIPHOSTS ""

ENTRYPOINT ["entrypoint.sh"]
CMD ["httpd-foreground"]
