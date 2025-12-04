namespace :news_api do
  desc "Open a console with a NewsApiAi::Client instance"
  task console: :environment do
    require "irb"

    client = NewsApiAi::Client.new
    puts "NewsApiAi::Client loaded as `client`"
    puts "Try: client.top_headlines(country: 'us')"

    binding.irb
  end
end
