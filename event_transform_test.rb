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

  def assert_with_warn(file_name, body, field)
    if !body.has_key?(field)
      warn "#{file_name} doesn't have an #{field} key set"
    else
      assert body.has_key?(field)
    end
  end

  def test_parsed_structure
    (2011..2016).each do |year|
      fixtures = Dir.glob("fixtures/#{year}/*_encoded.json")
      fixtures.each do |fixture|
        parsed = JSON.parse(File.open(fixture).read)
        assert_with_warn(fixture, parsed, 'type')
        assert_with_warn(fixture, parsed, 'public')
        assert_with_warn(fixture, parsed, 'payload')
        assert_with_warn(fixture, parsed, 'repo')
        assert_with_warn(fixture, parsed, 'actor')
        assert_with_warn(fixture, parsed, 'org')
        assert_with_warn(fixture, parsed, 'created_at')
        assert_with_warn(fixture, parsed, 'id')
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
