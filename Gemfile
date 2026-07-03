# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# relaton is now a single unpublished gem in the relaton/relaton monorepo. Pull
# it from main (HTTPS so the crawler GH action can clone the public repo
# anonymously, without an SSH key).
gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

# pubid 2.x is unpublished; track the branch carrying the lean IEC to_hash/from_hash
# for the index-v2 generation.
gem "pubid", git: "https://github.com/metanorma/pubid.git", branch: "rt-new-lutaml-model"

gem "pry-byebug"
