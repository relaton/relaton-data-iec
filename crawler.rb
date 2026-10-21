# frozen_string_literal: true

require "relaton/iec/data_fetcher"
require "bundler"

mode = ARGV.shift || "latest"
ENV["IEC_HAPI_PROJ_PUBS_KEY"] = ARGV.shift
ENV["IEC_HAPI_PROJ_PUBS_SECRET"] = ARGV.shift

# Only (re)generate index-v2 here; the legacy index-v1 is rebuilt separately below.
FileUtils.rm Dir.glob("index-v2*") unless mode == "latest"

# Build index-v2 (lean pubid#to_hash): fetch publications + index data/ and static/.
Relaton::Iec::DataFetcher.fetch("iec-harmonised-#{mode}")

# In-development projects: same Harmonized API (projects endpoint, same OAuth
# app), fetched into data/projects so the publications tree and its machine
# index stay publications-only; the API ingest picks the subtree up via its
# glob. Runs after the publications fetch because the all-mode rebuild wipes
# data/ wholesale.
Relaton::Iec::ProjectFetcher.fetch("iec-projects-#{mode}", output: "data/projects")

# Index static files into index-v2. Parse the docid into a pubid so they
# serialize as lean hashes like the fetched data (DataFetcher already indexes
# static during rebuild; this keeps the explicit pass for safety/clarity).
index = Relaton::Index.find_or_create :iec, file: "#{Relaton::Iec::INDEXFILE}.yaml",
                                      pubid_class: ::Pubid::Iec::Identifier
Dir["static/*.yaml"].each do |file|
  item = Relaton::Iec::Item.from_yaml File.read(file, encoding: "UTF-8")
  content = item.docidentifier.detect(&:primary)&.content
  next unless content

  pubid = begin
    Pubid::Iec::Identifier.parse(content)
  rescue StandardError
    next
  end
  index.add_or_update pubid, file
end
index.save

# Regenerate the legacy index-v1 (flat pubid-iec v1 hash) for older relaton-iec
# versions. pubid v1 and v2 define the same Pubid::Iec::Identifier constant and
# cannot share a process, so run it under Gemfile.legacy in a child process.
Bundler.with_unbundled_env do
  env = { "BUNDLE_GEMFILE" => File.expand_path("Gemfile.legacy", __dir__) }
  system(env, "bundle", "install", "--quiet") || abort("legacy bundle install failed")
  system(env, "bundle", "exec", "ruby", File.expand_path("crawler_legacy.rb", __dir__)) ||
    abort("crawler_legacy.rb failed")
end

# Stage the incremental cursor so it gets committed. The reusable crawler workflow
# (relaton/support) only stages data/* and index*.yaml; per its contract, "any
# files except 'data/*', index.yaml have to be committed explicitly". Without this
# last_change.txt is written to disk by DataFetcher#save_last_change but never
# committed, so every run re-queries from the same stale cursor.
%w[last_change.txt last_change_projects.txt].each do |name|
  cursor = File.expand_path(name, __dir__)
  system("git", "add", cursor) if File.exist?(cursor)
end
