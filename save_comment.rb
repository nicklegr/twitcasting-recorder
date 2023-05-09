# coding: utf-8

require "dotenv"
require "json"
require_relative "https"

API_BASE_URI = "https://apiv2.twitcasting.tv"
SLEEP_SEC = 3.0

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

movie_id = ARGV[0]

slice_id = nil

loop do
  begin
    params = {
      "limit" => "50",
      "slice_id" => slice_id || "1", # このコメントID以降のコメントを取得(指定したIDは含まない)
    }
    ret = get_json("/movies/#{movie_id}/comments", {}, params)

    ret => { comments: }
    comments.sort_by!{|e| e[:id].to_i}

    if comments.empty?
      sleep(SLEEP_SEC)
      next
    else
      slice_id = comments.last[:id]
    end

    text_comments = comments.map do |e|
      e => { created:, message:, from_user: { screen_id: }}
      time_str = Time.at(created).strftime("%Y/%m/%d %H:%M:%S")
      "[#{time_str}] #{message} (#{screen_id})"
    end

    jsonl_comments = comments.map{|e| e.to_json}

    File.open("comments_#{movie_id}.txt", "a") do |file|
      file.puts(text_comments.join("\n"))
    end

    File.open("comments_#{movie_id}.jsonl", "a") do |file|
      file.puts(jsonl_comments.join("\n"))
    end
  rescue Net::HTTPExceptions => e
    # エラーが起きても続行
    puts e.message
    puts e.response.body
    puts e.backtrace
  rescue => e
    puts e.message
    puts e.backtrace
  end

  sleep(SLEEP_SEC)
end
