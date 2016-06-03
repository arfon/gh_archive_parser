require 'zlib'
require 'yajl'
require_relative 'event_transform'

incoming = Dir.glob('files/*.json.gz')
parse_error_count = 0

incoming.each do |file|
  puts "*********************"
  puts "Working with #{file}"
  puts "*********************"
  gz = File.open(file, 'r')

  begin
    js = Zlib::GzipReader.new(gz).read
  rescue Zlib::GzipFile::Error
    puts "Empty file, no events"
    next
  end

  begin
    Yajl::Parser.parse(js) do |event|

      transformer = EventTransform.new(event)
      transformer.process
      encoded = Yajl::Encoder.encode(transformer.parsed_event)

      puts encoded
    end
  rescue Yajl::ParseError
    parse_error_count += 1
  end
end
