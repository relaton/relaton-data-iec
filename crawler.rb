# frozen_string_literal: true

require "relaton_iec"

mode = ARGV.shift || "latest"
ENV["IEC_HAPI_PROJ_PUBS_KEY"] = ARGV.shift
ENV["IEC_HAPI_PROJ_PUBS_SECRET"] = ARGV.shift

FileUtils.rm Dir.glob('index*') unless mode == "latest"
RelatonIec::DataFetcher.new("iec-harmonised-#{mode}").fetch
