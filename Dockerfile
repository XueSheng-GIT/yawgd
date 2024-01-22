FROM perl:5.32-slim

COPY /etc /etc
COPY /usr /usr

RUN apt-get update -y \
    && apt-get install -y libmath-round-perl libmath-basecalc-perl librrds-perl libproc-pid-file-perl libproc-daemon-perl librrds-perl libwww-perl curl \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /usr/sbin/yawgd.pl

CMD ["/usr/bin/perl", "/usr/sbin/yawgd.pl", "-d"]