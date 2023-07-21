# Docker file for Dev and Testing

FROM ruby:3.2.2-buster

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  \
  apt-get -y update && apt-get -y upgrade && \
  \
  DEBIAN_FRONTEND=noninteractive \
  \
  apt-get -y install apt-utils 2>&1 | grep -v "debconf: delaying package configuration, since apt-utils is not installed" && \
  \
  apt-get -y install \
    unattended-upgrades \
    apt-listchanges \
    imagemagick \
    build-essential \
    patch \
    ruby-dev \
    liblzma-dev \
    libssl-dev libreadline-dev zlib1g-dev \
    yarn \
    postgresql-client \
    netcat \
    tzdata && \
  \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN yarn install

COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app

ENV BUNDLE_PATH /gems
RUN echo "gem: --no-rdoc --no-ri" >> ~/.gemrc
RUN gem install bundler
RUN bundle config set --local clean 'true'
RUN bundle install --jobs 20 --retry 5

COPY . /usr/src/app/

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
