# frozen_string_literal: true

# One-shot conversion of the published records' status words to numeric
# harmonized stage codes (relaton#519), the same mapping
# Relaton::Iec::DataParser applies to freshly crawled records. Existing
# files keep their word (the crawler's incremental last-change skip never
# re-renders them), so this pass round-trips every record through the
# item model and rewrites only the status and ext.stagename fields -
# everything else serializes byte-stably. Records already numeric or
# word-less pass through unchanged.
#
#   bundle exec ruby convert_status.rb            # rewrite in place
#   bundle exec ruby convert_status.rb --check    # count only

require "bundler"
require "relaton/iec"

CHECK = ARGV.include?("--check")
TABLE = Relaton::Iec::DataParser::HARMONIZED_STATUS

converted = 0
skipped_numeric = 0
skipped_wordless = 0
failed = []

Dir["data/*.yaml"].sort.each do |file|
  item = Relaton::Iec::Item.from_yaml(File.read(file, encoding: "UTF-8"))
  word = item.status&.stage&.content.to_s

  if word.empty?
    skipped_wordless += 1
    next
  end
  code = TABLE[word]
  if code.nil?
    if word.match?(/\A\d+\z/)
      skipped_numeric += 1
      next
    end
    failed << [file, "unknown status word #{word.inspect}"]
    next
  end

  item.status = Relaton::Bib::Status.new(
    stage: Relaton::Bib::Status::Stage.new(content: code[0]),
    substage: Relaton::Bib::Status::Stage.new(content: code[1]),
  )
  item.ext.stagename = Relaton::Iec::StageName.new(abbreviation: word, content: word)

  next if CHECK

  File.write(file, item.to_yaml)
  converted += 1
rescue StandardError => e
  failed << [file, "#{e.class}: #{e.message[0, 80]}"]
end

puts "converted: #{converted}, already numeric: #{skipped_numeric}, wordless: #{skipped_wordless}, failed: #{failed.length}"
failed.each { |f, e| puts "  #{f}: #{e}" }
exit 1 unless failed.empty?
