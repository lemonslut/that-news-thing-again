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

  desc "Clear retries for job classes that no longer exist"
  task clear_dead_jobs: :environment do
    require "sidekiq/api"

    retry_set = Sidekiq::RetrySet.new
    cleared = Hash.new(0)

    retry_set.each do |job|
      job_class = job.item["wrapped"] || job.item["class"]
      unless Object.const_defined?(job_class)
        cleared[job_class] += 1
        job.delete
      end
    end

    if cleared.empty?
      puts "No dead job classes found"
    else
      puts "Cleared:"
      cleared.each { |klass, count| puts "  #{klass}: #{count}" }
    end
  end
end
