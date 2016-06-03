require 'yajl'
require 'yajl/json_gem'
require 'zlib'
require_relative '../event_transform'

# Count of all event types from 2011-02-15-0.json.gz
events_2011 = {"CommitCommentEvent"=>25, "CreateEvent"=>243, "DeleteEvent"=>12, "DownloadEvent"=>7, "FollowEvent"=>48, "ForkApplyEvent"=>2, "ForkEvent"=>41, "GistEvent"=>39, "GollumEvent"=>49, "IssuesEvent"=>65, "MemberEvent"=>11, "PublicEvent"=>1, "PullRequestEvent"=>40, "PushEvent"=>889, "WatchEvent"=>167}

# Count of all event types from 2012-02-15-0.json.gz
events_2012 = {"CommitCommentEvent"=>50, "CreateEvent"=>493, "DeleteEvent"=>35, "DownloadEvent"=>14, "FollowEvent"=>142, "ForkApplyEvent"=>2, "ForkEvent"=>108, "GistEvent"=>107, "GollumEvent"=>73, "IssueCommentEvent"=>360, "IssuesEvent"=>167, "MemberEvent"=>33, "PublicEvent"=>2, "PullRequestEvent"=>135, "PushEvent"=>1948, "WatchEvent"=>405}

# Count of all event types from 2013-02-15-0.json.gz
events_2013 = {"CommitCommentEvent"=>68, "CreateEvent"=>662, "DeleteEvent"=>47, "DownloadEvent"=>1, "FollowEvent"=>146, "ForkEvent"=>276, "GistEvent"=>15, "GollumEvent"=>109, "IssueCommentEvent"=>958, "IssuesEvent"=>619, "MemberEvent"=>33, "PublicEvent"=>1, "PullRequestEvent"=>231, "PullRequestReviewCommentEvent"=>60, "PushEvent"=>3048, "WatchEvent"=>577}

# Count of all event types from 2014-02-15-0.json.gz
events_2014 = {"CommitCommentEvent"=>41, "CreateEvent"=>780, "DeleteEvent"=>87, "ForkEvent"=>266, "GistEvent"=>76, "GollumEvent"=>149, "IssueCommentEvent"=>516, "IssuesEvent"=>324, "MemberEvent"=>26, "PublicEvent"=>8, "PullRequestEvent"=>260, "PullRequestReviewCommentEvent"=>35, "PushEvent"=>3712, "ReleaseEvent"=>14, "TeamAddEvent"=>8, "WatchEvent"=>817}

# Count of all event types from 2015-02-15-0.json.gz
events_2015 = {"CommitCommentEvent"=>70, "CreateEvent"=>1447, "DeleteEvent"=>205, "ForkEvent"=>372, "GollumEvent"=>129, "IssueCommentEvent"=>1025, "IssuesEvent"=>595, "MemberEvent"=>132, "PublicEvent"=>13, "PullRequestEvent"=>586, "PullRequestReviewCommentEvent"=>180, "PushEvent"=>7218, "ReleaseEvent"=>36, "WatchEvent"=>1204}

# Count of all event types from 2016-02-15-0.json.gz
events_2016 = {"CommitCommentEvent"=>81, "CreateEvent"=>2965, "DeleteEvent"=>381, "ForkEvent"=>578, "GollumEvent"=>262, "IssueCommentEvent"=>1567, "IssuesEvent"=>811, "MemberEvent"=>80, "PublicEvent"=>21, "PullRequestEvent"=>1194, "PullRequestReviewCommentEvent"=>320, "PushEvent"=>13730, "ReleaseEvent"=>59, "WatchEvent"=>1810}

(2011..2016).each do |year|
  # Make a directory for the fixtures
  `mkdir fixtures/#{year}`

  events = eval("events_#{year}")
  archive_file = "../#{year}-02-15-0.json.gz"
  gz = File.open(archive_file, 'r')

  begin
    js = Zlib::GzipReader.new(gz).read
  rescue Zlib::GzipFile::Error
    puts "Empty file, no events"
  end

  # For each event type (e.g. CommitCommentEvent) extract one example and write
  # it to the fixtures/year/CommitCommentEvent_raw.json
  events.keys.each do |event_type|
    extracted_count = 0
    Yajl::Parser.parse(js) do |event|
      next if extracted_count > 0
      if event_type == event['type']
        extracted_count += 1
        # Write out the fixture
        File.open("fixtures/#{year}/#{event_type}_raw.json", 'w') {|f| f.write(JSON.pretty_generate(event.sort.to_h)) }

        transformer = EventTransform.new(event)
        transformer.process
        tranformed_event = transformer.parsed_event
        # Write out the transformed event
        File.open("fixtures/#{year}/#{event_type}_transformed.json", 'w') {|f| f.write(JSON.pretty_generate(tranformed_event)) }

        encoded = Yajl::Encoder.encode(tranformed_event)
        # Finally write out the encoded event (what we load into BigQuery)
        File.open("fixtures/#{year}/#{event_type}_encoded.json", 'w') {|f| f.write(encoded.to_s) }
      end
    end
  end
end
