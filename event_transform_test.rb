require_relative 'event_transform'
require 'test/unit'
require 'yajl'
require 'yajl/json_gem'

class Hash
  def deep_diff(b)
    a = self
    (a.keys | b.keys).inject({}) do |diff, k|
      if a[k] != b[k]
        if a[k].respond_to?(:deep_diff) && b[k].respond_to?(:deep_diff)
          diff[k] = a[k].deep_diff(b[k])
        else
          diff[k] = [a[k], b[k]]
        end
      end
      diff
    end
  end
end

class TestEventTransform < Test::Unit::TestCase
  def test_parsed_structure
    (2011..2016).each do |year|
      fixtures = Dir.glob("fixtures/#{year}/*_encoded.json")
      fixtures.each do |fixture|
        parsed = JSON.parse(File.open(fixture).read)
        assert parsed.has_key?('type')
        assert parsed.has_key?('public')
        assert parsed.has_key?('payload')
        assert parsed.has_key?('repo')
        assert parsed.has_key?('actor')
        assert parsed.has_key?('org')
        assert parsed.has_key?('created_at')
        assert parsed.has_key?('id')
      end
    end
  end

  def test_transformer
    (2011..2016).each do |year|
      raw_events = Dir.glob("fixtures/#{year}/*_raw.json")
      raw_events.each do |event_name|
        event = File.open(event_name).read
        expected_name = event_name.gsub('raw', 'transformed')
        expected = File.open(expected_name).read

        transformer = EventTransform.new(JSON.parse(event))
        transformer.process
        assert transformer.parsed_event.deep_diff(JSON.parse(expected)).empty?, "Failed for #{expected_name}"
      end
    end
  end
end
