namespace :searchkick do # rubocop:disable Metrics/BlockLength
  desc 'Reindex all models'
  task reindex_all: :environment do
    puts 'Reindexing all models...'

    models = [User, Micropost]

    models.each do |model|
      puts "Reindexing #{model.name}..."
      model.reindex
      puts "✓ #{model.name} reindexed"
    end

    puts 'Done! All models have been reindexed.'
  end

  desc 'Reindex a specific model (usage: rake searchkick:reindex[User])'
  task :reindex, [:model] => :environment do |_, args|
    if args[:model].blank?
      puts 'Usage: rake searchkick:reindex[ModelName]'
      puts 'Example: rake searchkick:reindex[User]'
      exit
    end

    model_name = args[:model]
    model = model_name.constantize rescue nil # rubocop:disable Style/RescueModifier

    if model.nil? || !model.respond_to?(:reindex)
      puts "Error: #{model_name} is not a valid searchable model"
      exit
    end

    puts "Reindexing #{model_name}..."
    model.reindex
    puts "✓ #{model_name} reindexed successfully"
  end

  desc 'Clear all indexes'
  task clear_all: :environment do
    puts 'Clearing all indexes...'

    models = [User, Micropost]

    models.each do |model|
      puts "Clearing #{model.name} index..."
      model.searchkick_index.delete if model.searchkick_index.exists?
      puts "✓ #{model.name} index cleared"
    end

    puts 'Done! All indexes have been cleared.'
  end

  desc 'Clear a specific model index (usage: rake searchkick:clear[User])'
  task :clear, [:model] => :environment do |_, args|
    if args[:model].blank?
      puts 'Usage: rake searchkick:clear[ModelName]'
      puts 'Example: rake searchkick:clear[User]'
      exit
    end

    model_name = args[:model]
    model = model_name.constantize rescue nil # rubocop:disable Style/RescueModifier

    if model.nil? || !model.respond_to?(:searchkick_index)
      puts "Error: #{model_name} is not a valid searchable model"
      exit
    end

    puts "Clearing #{model_name} index..."
    model.searchkick_index.delete if model.searchkick_index.exists?
    puts "✓ #{model_name} index cleared successfully"
  end

  desc 'Check Solr connection'
  task check: :environment do
    puts 'Checking Solr connection...'

    solr_url = ENV.fetch('SOLR_URL', 'http://localhost:8983/solr')
    puts "Solr URL: #{solr_url}"

    begin
      require 'rsolr'
      solr = RSolr.connect(url: solr_url)
      response = solr.get 'admin/ping'

      if response['status'] == 'OK'
        puts '✓ Solr connection successful!'
        puts "  Status: #{response['status']}"
      else
        puts '✗ Solr connection failed'
        puts "  Response: #{response.inspect}"
      end
    rescue StandardError => e
      puts "✗ Error connecting to Solr: #{e.message}"
      puts '  Make sure Solr is running: docker-compose up solr'
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
