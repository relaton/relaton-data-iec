# frozen_string_literal: true

require "relaton_iec"

mode = ARGV.shift || "latest"
ENV["IEC_HAPI_PROJ_PUBS_KEY"] = ARGV.shift
ENV["IEC_HAPI_PROJ_PUBS_SECRET"] = ARGV.shift

t1 = Time.now
puts "Started at: #{t1}"

RelatonIec::DataFetcher.new("iec-harmonised-#{mode}").fetch
system("zip index.zip index.yaml")
system("git add index.zip index.yaml")

t2 = Time.now
puts "Stopped at: #{t2}"
puts "Done in: #{(t2 - t1).round} sec."