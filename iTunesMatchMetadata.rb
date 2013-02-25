#!/usr/bin/env ruby
# by @tapbot_paul
# Don't blame me if this nukes your metadata, formats your drive, kills your kids
# This script goes through any iCloud Matched songs in your iTunes library and tries to update the 
# metadata from the iTunes Store
# Will run against selected tracks or if nothing selected entire library
# install the required gems with the following commands
# sudo gem install json
# sudo gem install rb-appscript
# then run the script with "ruby meta.rb"
require 'rubygems'
require 'appscript'
require 'json'
require 'open-uri'
require("~/Library/iTunes/tunes.rb")

class Track
  attr_reader :iTunes_id
  attr_reader :iTunes_track
def initialize(iTunes_track)
  @iTunes_track = iTunes_track
  path = @iTunes_track.location.get.path
  file_string = File.open(path, 'r').read(1024) # data always seems to be around 600-700 bytes in
  index = file_string.index('song')
  if index
    @iTunes_id = file_string[index+4,4].unpack('N')[0]
  else
    puts "Couldn't find @iTunes_track id #{track.name.get}"
  end
end

def valid?
  @iTunes_id.nil?
end

def update_track(result)
  @iTunes_track.name.set(result['trackName'])
  @iTunes_track.album.set(result['collectionName'])
  @iTunes_track.artist.set(result['artistName'])
  @iTunes_track.track_count.set(result['trackCount'])
  @iTunes_track.track_number.set(result['trackNumber'])
  @iTunes_track.genre.set(result['primaryGenreName'])
  @iTunes_track.disc_count.set(result['discCount'])
  @iTunes_track.disc_number.set(result['discNumber'])
end

end

WORK_SIZE = 100
STDOUT.sync = true
tracks = []

app = Appscript.app.by_name("iTunes", Tunes)

iTunes_tracks = app.selection.get
if iTunes_tracks.count == 0
  iTunes_tracks = app.library_playlists[1].tracks.get
end

print "Reading #{iTunes_tracks.count} tracks "
iTunes_tracks.each do | iTunes_track |
  begin
    if iTunes_track.kind.get == 'Matched AAC audio file'
      track = Track.new(iTunes_track)
      unless track.valid?
        tracks << track
        print '*' if ((tracks.count % WORK_SIZE) == 0)
      end
    end
  rescue StandardError => e
    puts e
  end
end
puts ''

# all 2 char countries codes lots currently not valid %w(AF AX AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ BM BT BO BQ BA BW BV BR IO BN BG BF BI KH CM CA CV KY CF TD CL CN CX CC CO KM CG CD CK CR CI HR CU CW CY CZ DK DJ DM DO EC EG SV GQ ER EE ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG GN GW GY HT HM VA HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MK MG MW MY MV ML MT MH MQ MR MU YT MX FM MD MC MN ME MS MA MZ MM NA NR NP NL NC NZ NI NE NG NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA RE RO RU RW BL SH KN LC MF PM VC WS SM ST SA SN RS SC SL SG SX SK SI SB SO ZA GS SS ES LK SD SR SJ SZ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV UG UA AE GB US UM UY UZ VU VE VN VG VI WF EH YE ZM ZW)

countries = %w(AU US GB FR DE CA IT JP DZ AO AI AG AR AM AT AZ BS BH BD BB BY BE BZ BM BO BW BR BN BG CM KY CL CN CO CR CI HR CY CZ DK DM DO EC EG SV EE ET FI GH GR GD GT GY HN HK HU IS IN ID IE IL JM JO KZ KE KR KW LV LB LY LI LT LU MO MK MG MY MV ML MT MU MX MD MS MM NP NL NZ NI NE NG NO OM PK PA PY PE PH PL PT QA RO RU KN LC VC SA SN RS SG SK SI ZA ES LK SR SE CH TW TZ TH TT TN TR TC UG UA AE UY UZ VE VN VG YE)

puts "Found #{tracks.count} matched tracks"
countries.each do | country |
  print "Querying #{country} store for #{tracks.count} tracks "
  counter = 0
  tracks.dup.each.each_slice(WORK_SIZE) do | subtracks |
    ids = subtracks.map { | track | track.iTunes_id }
    iTunesHash = JSON.parse(open("http://itunes.apple.com/lookup?id=#{ids.join(',')}&country=#{country}").read)
    print '*'
    iTunesHash['results'].each do | result |
      result_id = result['trackId']
      subtracks.each do | track |
        if result_id == track.iTunes_id
          track.update_track(result)
          tracks.delete(track)
          counter += 1
          break
        end
      end
    end
  end
  puts " #{counter} updated"
  break if tracks.empty?
end

puts "Couldn't find meatadata for #{tracks.count} tracks" if tracks.count != 0

