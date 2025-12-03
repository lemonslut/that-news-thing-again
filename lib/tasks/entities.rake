namespace :entities do
  desc "Backfill entities from existing article analyses"
  task backfill: :environment do
    count = 0
    ArticleAnalysis.includes(:article).find_each do |analysis|
      analysis.link_entities_from_result(analysis.raw_response || {}, analysis.article)
      count += 1
      print "." if count % 10 == 0
    end
    puts "\nBackfilled entities for #{count} analyses"
    puts "Total entities: #{Entity.count}"
  end
end
