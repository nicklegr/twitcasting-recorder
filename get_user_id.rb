# coding: utf-8

require "dotenv"
require "json"
require_relative "https"

API_BASE_URI = "https://apiv2.twitcasting.tv"

def get_json(uri, header = {}, params = {}, body = "")
  common_header = {
    "Accept" => "application/json",
    "X-Api-Version" => "2.0",
    "Authorization" => "Bearer #{ENV["ACCESS_TOKEN"]}",
  }

  body = Https.get("#{API_BASE_URI}#{uri}", common_header.merge(header), params, body)
  JSON.parse(body, symbolize_names: true)
end

Dotenv.load
Encoding.default_external = Encoding::UTF_8

File.readlines(ARGV.shift).each do |line|
  screen_id = line.match(/^([^,]+)/)[1]

  begin
    user = get_json("/users/#{screen_id}")
    user => {user: {id:, screen_id:, name:, is_live:, last_movie_id:}}

    puts "- #{id} # #{screen_id}"
  rescue
    puts "- #{screen_id}"
  end

  sleep(1.0)
end
