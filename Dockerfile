FROM kcov/kcov

RUN apt-get update && \
    apt-get install -y --no-install-recommends inotify-tools psmisc && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app

CMD ["kcov", "--verify", "--bash-method=DEBUG", "--exclude-path=.git,coverage,setup.sh", "/app/coverage", "/app/test.sh"]
