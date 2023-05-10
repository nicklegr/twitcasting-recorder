# coding: utf-8

require 'pp'
require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'dotenv'
require_relative 'https'

Dotenv.load

get '/' do
  <<~EOD
    <a href="https://apiv2.twitcasting.tv/oauth2/authorize?client_id=#{ENV["CLIENT_ID"]}&response_type=code">Get access token</a>
  EOD
end

get '/callback' do
  code = params["code"]

  body = Https.post("https://apiv2.twitcasting.tv/oauth2/access_token",
    {},
    {
      "code" => code,
      "grant_type" => "authorization_code",
      "client_id" => ENV["CLIENT_ID"],
      "client_secret" => ENV["CLIENT_SECRET"],
      "redirect_uri" => ENV["REDIRECT_URI"],
    })

  res = JSON.parse(body, symbolize_names: true)
  res => { access_token:, expires_in: }

  <<~EOD
    Access token: #{access_token} <br/>
    (Expires in #{expires_in / 3600.0 / 24} days)
  EOD
end
