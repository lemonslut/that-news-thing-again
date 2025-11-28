namespace :news_api do
  desc "Open a console with a NewsApi::Client instance"
  task console: :environment do
    require "irb"

    client = NewsApi::Client.new
    puts "NewsApi::Client loaded as `client`"
    puts "Try: client.top_headlines(country: 'us')"

    binding.irb
  end
end
