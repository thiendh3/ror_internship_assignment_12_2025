namespace :searchkick do
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
  task :reindex, [:model] => :environment do |_t, args|
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
  task :clear, [:model] => :environment do |_t, args|
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

  desc 'Check Elasticsearch connection'
  task check: :environment do
    puts 'Checking Elasticsearch connection...'

    es_url = ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200')
    puts "Elasticsearch URL: #{es_url}"

    begin
      client = Searchkick.client
      health = client.cluster.health

      if health
        puts '✓ Elasticsearch connection successful!'
        puts "  Cluster: #{health['cluster_name']}"
        puts "  Status: #{health['status']}"
        puts "  Number of nodes: #{health['number_of_nodes']}"
      else
        puts '✗ Elasticsearch connection failed'
      end
    rescue StandardError => e
      puts "✗ Error connecting to Elasticsearch: #{e.message}"
      puts '  Make sure Elasticsearch is running: docker-compose up elasticsearch'
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
