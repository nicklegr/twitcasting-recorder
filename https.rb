# coding: utf-8

require "net/http"
require "openssl"
require "fileutils"
require "json"
require "pp"
require "time"

class Https
  def self.get(url, header, params = {}, body = "")
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    net = Net::HTTP.new(uri.hostname, uri.port)
    net.use_ssl = (uri.scheme == "https")
    # net.verify_mode = OpenSSL::SSL::VERIFY_NONE
    net.start() do |http|
      req = Net::HTTP::Get.new(uri, header)
      req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"
      req.body = body
      res = http.request(req)
      res.value # raise exception if failed

      res.body
    end
  end

  def self.post(url, header, params = {}, body = "")
    uri = URI(url)

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = (uri.scheme == "https")
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    res = http.start do
      req = Net::HTTP::Post.new(uri, header)
      req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"
      req.set_form_data(params)
      req.body = body
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      res.body
    else
      # レスポンスが 2xx(成功)でなかった場合に、対応する例外を発生させます。
      res.value
    end
  end

  def self.get_ret_header(url, header, params = {}, body = "")
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    net = Net::HTTP.new(uri.hostname, uri.port)
    net.use_ssl = (uri.scheme == "https")
    # net.verify_mode = OpenSSL::SSL::VERIFY_NONE
    net.start() do |http|
      req = Net::HTTP::Get.new(uri, header)
      req["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"
      req.body = body
      res = http.request(req)
      res.value # raise exception if failed

      res
    end
  end
end
