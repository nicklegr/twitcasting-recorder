# coding: utf-8

require "dotenv"
require "json"
require_relative "https"

API_BASE_URI = "https://apiv2.twitcasting.tv"
SLEEP_SEC = 3.0
SLEEP_SEC_RATE_LIMIT = 10

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

raise "usage: #{__FILE__} <movie_id> <base_file_name>" if ARGV.size != 2

movie_id, base_file_name = ARGV
slice_id = nil

loop do
  begin
    # 配信終了チェック
    live = get_json("/movies/#{movie_id}")
    live => {movie: {is_live:}}
    exit(0) unless is_live

    # コメント取得
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

    File.open("#{base_file_name}.txt", "a") do |file|
      file.puts(text_comments.join("\n"))
    end

    File.open("#{base_file_name}.jsonl", "a") do |file|
      file.puts(jsonl_comments.join("\n"))
    end
  rescue Net::HTTPExceptions => e
    begin
      body = JSON.parse(e.response.body, symbolize_names: true)
      if e.response.code == "403" &&
        body in { error: { code: 2000 }}
        # レートリミットの場合は少し時間を空けて続行
        # 403 "Forbidden"
        # {"error":{"code":2000,"message":"Execution count limitation"}}
        puts "rate limit reached, sleeping #{SLEEP_SEC_RATE_LIMIT} sec"
        sleep(SLEEP_SEC_RATE_LIMIT)
        next
      end
    rescue JSON::ParserError
    end

    puts e.message
    puts e.response.body
    puts e.backtrace
    exit(1)
  rescue => e
    puts e.message
    puts e.backtrace
    exit(1)
  end

  sleep(SLEEP_SEC)
end
