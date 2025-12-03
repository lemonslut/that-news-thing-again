namespace :db do
  namespace :snap do
    desc "Snapshot production database to local development"
    task production: :environment do
      config = ActiveRecord::Base.configurations.find_db_config(:development)
      db = config.database
      host = config.host || "localhost"
      user = config.configuration_hash[:username] || "news"
      password = config.configuration_hash[:password]

      prod_host = "5.78.158.95"
      prod_container = "news-digest-postgres"
      prod_db = "news_production"
      prod_user = "news"

      dump_file = "/tmp/#{prod_db}_#{Time.now.strftime('%Y%m%d%H%M%S')}.dump"

      puts "Dumping #{prod_db} from #{prod_host}..."
      system("ssh root@#{prod_host} 'docker exec #{prod_container} pg_dump -U #{prod_user} -Fc #{prod_db}' > #{dump_file}")

      unless File.exist?(dump_file) && File.size(dump_file) > 0
        abort "Failed to dump production database"
      end

      puts "Restoring to #{db}..."
      env = password ? { "PGPASSWORD" => password } : {}
      system(env, "pg_restore --clean --no-owner --no-acl -h #{host} -U #{user} -d #{db} #{dump_file} 2>/dev/null")

      puts "Cleaning up..."
      File.delete(dump_file)

      article_count = Article.count
      analysis_count = ArticleAnalysis.count
      puts "Done. Articles: #{article_count}, Analyses: #{analysis_count}"
    end
  end
end
