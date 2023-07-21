FROM jekyll/jekyll

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle update ruby_dep

RUN bundle install --quiet --clean

CMD ["jekyll", "serve"]
