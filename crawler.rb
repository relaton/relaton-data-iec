# frozen_string_literal: true

require "relaton/iec/data_fetcher"

mode = ARGV.shift || "latest"
ENV["IEC_HAPI_PROJ_PUBS_KEY"] = ARGV.shift
ENV["IEC_HAPI_PROJ_PUBS_SECRET"] = ARGV.shift

FileUtils.rm Dir.glob('index*') unless mode == "latest"
Relaton::Iec::DataFetcher.fetch("iec-harmonised-#{mode}")

#
# Add static files to index.
#
index = Relaton::Index.find_or_create :iec, file: "#{Relaton::Iec::INDEXFILE}.yaml"

Dir["static/*.yaml"].each do |file|
  item = Relaton::Iec::Item.from_yaml File.read(file, encoding: "UTF-8")
  pubid = item.docidentifier.detect(&:primary).content
  index.add_or_update pubid, file
end

index.save
