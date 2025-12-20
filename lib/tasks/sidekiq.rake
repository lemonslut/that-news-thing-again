namespace :sidekiq do
  desc "Check queue depths and retry/dead counts"
  task queue_depth: :environment do
    require "sidekiq/api"

    puts "Queues:"
    Sidekiq::Queue.all.each do |queue|
      puts "  #{queue.name}: #{queue.size}"
    end

    puts
    puts "Retry: #{Sidekiq::RetrySet.new.size}"
    puts "Dead: #{Sidekiq::DeadSet.new.size}"
    puts "Scheduled: #{Sidekiq::ScheduledSet.new.size}"
  end
end
