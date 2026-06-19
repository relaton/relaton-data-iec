# frozen_string_literal: true
#
# Regenerate the legacy index-v1 (flat pubid-iec v1 #to_h hash, e.g.
# {publisher: "IEC", number: "01", year: 2017, type: "CA"}) for previous
# relaton-iec versions that still download index-v1.
#
# pubid-iec is pubid v1 and cannot share a process with the unified pubid v2 that
# crawler.rb uses for index-v2 (both define Pubid::Iec::Identifier), so this runs
# under its own Gemfile:
#
#   BUNDLE_GEMFILE=Gemfile.legacy bundle exec ruby crawler_legacy.rb
#
# The primary docid is read straight from the data YAML rather than via
# relaton-iec: the data is in the unified lutaml format the legacy stack cannot
# parse, and only the docid string is needed here.

require "fileutils"
require "yaml"
require "relaton/index"
require "pubid-iec"

FileUtils.rm Dir.glob("index-v1*")

# pubid_class makes relaton-index serialize each pubid via #to_h and sort the
# index by document number (matching the original index-v1).
idx = Relaton::Index.find_or_create :IEC, file: "index-v1.yaml",
                                    pubid_class: ::Pubid::Iec::Identifier

(Dir["data/*.yaml"] + Dir["static/*.yaml"]).each do |f|
  data = YAML.safe_load(File.read(f, encoding: "UTF-8"))
  docid = (data["docidentifier"] || []).find { |d| d["primary"] }
  next unless docid

  pubid = Pubid::Iec::Identifier.parse(docid["content"])
  idx.add_or_update pubid, f
rescue StandardError => e
  puts "Error processing #{f}: #{e.message}"
end

idx.save
