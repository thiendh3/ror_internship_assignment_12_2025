namespace :solr do
  desc 'Configure Solr Schema with EdgeNGram (minGramSize: 1)'
  task setup: :environment do
    SolrSetupService.setup
  end

  desc 'Reindex all user records to Solr'
  task reindex: :environment do
    puts 'Starting reindex...'

    count = 0
    errors = 0

    User.find_each do |user|
      user.index_to_solr
      count += 1
      print '.' if (count % 50).zero?
    rescue StandardError => e
      puts "\nFailed to index User ##{user.id}: #{e.message}"
      errors += 1
    end

    puts "\nReindexing complete."
    puts "Successfully indexed: #{count}"
    puts "Errors encountered: #{errors}"
  end
end
