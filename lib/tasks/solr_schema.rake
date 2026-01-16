namespace :solr do
  desc 'Configure Solr Schema with EdgeNGram (minGramSize: 1)'
  task setup: :environment do
    conn = SolrService.connection
    puts 'Configuring Solr Schema...'

    # 1. Define 'text_autocomplete' Field Type
    field_type_def = {
      name: 'text_autocomplete',
      class: 'solr.TextField',
      positionIncrementGap: '100',
      indexAnalyzer: {
        tokenizer: { class: 'solr.StandardTokenizerFactory' },
        filters: [
          { class: 'solr.LowerCaseFilterFactory' },
          {
            class: 'solr.EdgeNGramFilterFactory',
            minGramSize: 1,
            maxGramSize: 20
          }
        ]
      },
      queryAnalyzer: {
        tokenizer: { class: 'solr.StandardTokenizerFactory' },
        filters: [{ class: 'solr.LowerCaseFilterFactory' }]
      }
    }

    # Helper to add or replace
    def update_solr(conn, type, name, payload)
      conn.post 'schema', data: { "add-#{type}": payload }.to_json
      puts "Created #{type} '#{name}'."
    rescue RSolr::Error::Http => e
      raise e unless e.message.include?('already exists')

      puts "#{type.capitalize} '#{name}' exists. Replacing..."
      conn.post 'schema', data: { "replace-#{type}": payload }.to_json
      puts "Replaced #{type} '#{name}'."
    end

    # Execute Updates
    update_solr(conn, 'field-type', 'text_autocomplete', field_type_def)

    # 2. Configure Fields
    %w[name_ac email_ac bio_ac].each do |field|
      field_def = { name: field, type: 'text_autocomplete', stored: true, indexed: true }
      update_solr(conn, 'field', field, field_def)
    end

    # 3. Configure Standard Fields
    %w[name_text email_text bio_text].each do |field|
      field_def = { name: field, type: 'text_general', stored: true, indexed: true }
      update_solr(conn, 'field', field, field_def)
    end

    # 4. Configure Boolean Field
    update_solr(conn, 'field', 'active_boolean',
                { name: 'active_boolean', type: 'boolean', stored: true, indexed: true })

    puts 'Schema setup complete.'
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
