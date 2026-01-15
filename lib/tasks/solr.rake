namespace :solr do
  desc 'Reindex Microposts into Solr by re-saving each record'
  task reindex_microposts: :environment do
    puts 'Reindexing Microposts into Solr...'

    count = 0
    Micropost.find_each do |micropost|
      micropost.save!(touch: true)
      count += 1
      print "\rIndexed: #{count}" if (count % 50).zero?
    end

    puts "\nDone! Indexed #{count} microposts."
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
