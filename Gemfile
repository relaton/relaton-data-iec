# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# relaton-iec lives in the relaton/relaton monorepo. Pull it and its unpublished
# 2.2.x sibling gems from main, where the index-v2 work has landed (HTTPS so the
# crawler GH action can clone the public repo anonymously, without an SSH key).
git "https://github.com/relaton/relaton.git", branch: "main", glob: "gems/*/*.gemspec" do
  gem "relaton-iec"
  gem "relaton-iso"
  gem "relaton-bib"
  gem "relaton-core"
  gem "relaton-index"
  gem "relaton-logger"
end

# pubid 2.x is unpublished; track the branch carrying the lean IEC to_hash/from_hash
# for the index-v2 generation.
gem "pubid", git: "https://github.com/metanorma/pubid.git", branch: "rt-new-lutaml-model"

gem "pry-byebug"
