FROM photon:3.0-20200424
USER root
RUN tdnf distro-sync --refresh -y \
    && tdnf install -y \
    rubygem-fluentd-1.6.3 \
    # Transitive dependencies of fluent-plugin-kubernetes_metadata_filter-2.2.0
    # that are not automatically picked for some reason
    rubygem-concurrent-ruby-1.0.5 \
    rubygem-i18n-1.1.0 \
    #
    # Optional but used by fluentd
    rubygem-oj-3.3.10 \
    rubygem-async-http-0.48.2 \
    jemalloc-4.5.0 \
    #
    # Fluentd plugins
    rubygem-fluent-plugin-systemd-1.0.1 \
    rubygem-fluent-plugin-concat-2.4.0 \
    rubygem-fluent-plugin-kubernetes_metadata_filter-2.2.0 \
    rubygem-fluent-plugin-remote_syslog-1.0.0
RUN gem install fluent-plugin-docker_metadata_filter -v 0.1.3
RUN gem install fluent-plugin-detect-exceptions
RUN gem install fluent-plugin-multi-format-parser
RUN ln -s /usr/lib/ruby/gems/2.5.0/bin/fluentd /usr/bin/fluentd \
    && mkdir -p /fluentd/etc /fluentd/plugins \
    && fluentd --setup /fluentd/etc \
    && rmdir /fluentd/etc/plugin
# Latest version of fluentd output plugins
COPY ./ /fluentd/plugins/
WORKDIR /fluentd/plugins/
RUN gem build fluent-plugin-vmware-log-intelligence.gemspec
RUN gem install fluent-plugin-vmware-log-intelligence
RUN gem list
ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"
WORKDIR /
RUN rm -rf /fluentd/plugins/