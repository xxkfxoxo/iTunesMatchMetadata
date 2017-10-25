# iTunes Match Metadata Updater

## About

A small ruby script to update song metadata with itunes store data. This only works for matched tracks (Kind: Matched AAC audio file). 

## Prerequisites

* OS X >= 10.11
* Ruby ~2.x

## Usage

```
bundle install
bundle exec ruby iTunesMatchMetadata.rb

# Example with dry run and update year with release year:
bundle exec ruby iTunesMatchMetadata.rb -d -y

# See help for all options:
bundle exec ruby iTunesMatchMetadata.rb -h
```

