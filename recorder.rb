# coding: utf-8

require "time"
require "json"
require "yaml"
require "open-uri"
require "dotenv"
require "optparse"
require "fileutils"
require_relative "https"

API_BASE_URI = "https://apiv2.twitcasting.tv"
SLEEP_SEC_PER_USER = 1.0
SLEEP_SEC_PER_LOOP = 1.0

def ffmpeg_path
  if RUBY_PLATFORM == "x64-mingw32"
    "ffmpeg.exe"
  else
    "ffmpeg"
  end
end

def sanitize_filename(file)
  file.gsub(%r![/\\?*:|"<>]!, "")
end

class Option
  def initialize
    opt = OptionParser.new

    @rec_dir_name = "twicas"

    opt.on("--users_yaml=[filename]") {|v| @users_yaml = v }
    opt.on("--rec_dir_name=[name]") {|v| @rec_dir_name = v }

    opt.parse!(ARGV)
  end

  attr_reader :users_yaml
  attr_reader :rec_dir_name
end

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

option = Option.new

raise "usage: #{__FILE__} --users_yaml=<filename> [--rec_dir_name=<name>]" if !option.users_yaml

# TODO: ffmpegの存在をチェック

recording_pids = Hash.new {|hash, key| hash[key] = Hash.new}
pid_watchers = Hash.new {|hash, key| hash[key] = Hash.new}

loop do
  user_ids = YAML.load_file(option.users_yaml)
# pp user_ids
# pp user_ids.size

  user_ids.each do |user_id|
    begin
# pp recording_pids
# pp pid_watchers
$stdout.flush

      user = get_json("/users/#{user_id}")
      user => {user: {id:, screen_id:, name:, is_live:, last_movie_id:}}
      if !is_live
        sleep(SLEEP_SEC_PER_USER)
        next
      end

      # ライブ情報取得
      # ライブ終了する瞬間だと404になり得るが、他の通信エラーとまとめてrescueで拾う
      live = get_json("/movies/#{last_movie_id}")
      live => {movie: {title:, subtitle:, large_thumbnail:, hls_url:}}

      dir = "#{option.rec_dir_name}/#{screen_id}-#{id}"
      FileUtils.mkdir_p(dir)
      time_str = Time.now.strftime("%Y%m%d_%H%M%S")

      # 録画中かチェック
      watcher = pid_watchers.dig(last_movie_id, "video")
      if !watcher || !watcher.status
        # 録画開始
        video_filename = "#{dir}/" + sanitize_filename("#{time_str}-#{name}-#{last_movie_id}-#{title}-#{subtitle}.ts")
        puts "recording video '#{video_filename}'"

        video_recorder_pid = spawn(
          ffmpeg_path,
          "-hide_banner",
          "-loglevel",
          "warning",
          "-i",
          hls_url,
          "-c",
          "copy",
          video_filename
        )

        recording_pids[last_movie_id]["video"] = video_recorder_pid
        pid_watchers[last_movie_id]["video"] = Process.detach(video_recorder_pid)
      else
        puts "already recording video: #{screen_id} (movie_id: #{last_movie_id}, pid: #{recording_pids[last_movie_id]["video"]})"
      end
    rescue Net::HTTPExceptions => e
      puts e.message
      puts e.response.body
      puts e.backtrace
    rescue NoMatchingPatternError => e
      puts e.message
      puts e.backtrace
    rescue => e
      puts e.message
      puts e.backtrace
    end

    sleep(SLEEP_SEC_PER_USER)
  end

  sleep(SLEEP_SEC_PER_LOOP)
end
