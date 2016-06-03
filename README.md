# GitHub Archive Parser

Some rather unpleasant code that can be used to normalize the structure of GitHub public events across the years.

[![Build Status](https://travis-ci.org/arfon/gh_archive_parser.svg?branch=master)](https://travis-ci.org/arfon/gh_archive_parser)

## Usage

Assuming you have a folder called `files` with a bunch of [GitHub Archive](https://www.githubarchive.org/) compressed JSON files e.g. `http://data.githubarchive.org/2015-01-01-15.json.gz` then the following code should extract the JSON and normalize it to the schema expected by the GitHub Archive ([`schema.js`](https://github.com/igrigorik/githubarchive.org/blob/master/bigquery/schema.js)).

```ruby
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
```
