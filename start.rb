require 'rubygems'
require 'sinatra'
require 'sass'
require 'mail'
require 'json'
require './model/comment.rb'

set :bind, '0.0.0.0'

vcap_services = JSON.parse(ENV['VCAP_SERVICES'])
to_addr = vcap_services["user-provided"][0]["credentials"]["to_addr"]
address = vcap_services["user-provided"][0]["credentials"]["address"]
port = vcap_services["user-provided"][0]["credentials"]["port"]
domain = vcap_services["user-provided"][0]["credentials"]["domain"]
user_name = vcap_services["user-provided"][0]["credentials"]["user_name"]
password = vcap_services["user-provided"][0]["credentials"]["password"]
authentication = vcap_services["user-provided"][0]["credentials"]["authentication"]

Mail.defaults do
  delivery_method :smtp, { :address     => address,
                        :port           => port.to_i,
                        :domain         => domain,
                        :user_name      => user_name,
                        :password       => password,
                        :authentication => authentication }
end

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/' do
  haml :index
end

put '/comment' do
  $form_info = Comments.create({
    :namae => request[:namae],
    :address => request[:address],
    :attend => request[:attend],
    :bootha => request[:bootha],
    :boothb => request[:boothb],
    :boothc => request[:boothc],
    :eval => request[:eval],
    :message => request[:message],
    :posted_date => Time.now,
  })

  unless $form_info[:bootha]
    $form_info[:bootha] = " "
  end
  unless $form_info[:boothb]
    $form_info[:boothb] = " "
  end
  unless $form_info[:boothc]
    $form_info[:boothc] = " "
  end

  result = "お名前: " + $form_info[:namae] + "\n"
  result += "メールアドレス: " + $form_info[:address] + "\n"
  result += "参加日: " + $form_info[:attend] + "\n"
  result += "参加ブース: " + $form_info[:bootha] + " " + $form_info[:boothb] + " " + $form_info[:boothc] + "\n"
  result += "評価: " + $form_info[:eval] + "\n"

  result = Rack::Utils.escape_html(result).gsub(/\n/, "<br>")

  result += "メッセージ: " + $form_info.formatted_message + "\n"

  mail = Mail.new do
    to to_addr
    from 'ied@lab.ntt.co.jp'
    subject 'アンケート結果'
    text_part do
      body result
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      html = "<b>" + result + "</b>"
      body html
    end
  end
  mail.deliver

  haml :thanks
end
