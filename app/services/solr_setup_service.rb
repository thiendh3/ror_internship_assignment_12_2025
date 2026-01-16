class SolrSetupService
  def self.setup
    new.setup
  end

  def setup
    conn = SolrService.connection
    puts 'Configuring Solr Schema...'

    update_field_types(conn)
    update_autocomplete_fields(conn)
    update_standard_fields(conn)
    update_boolean_fields(conn)

    puts 'Schema setup complete.'
  end

  private

  def update_field_types(conn)
    field_type_def = {
      name: 'text_autocomplete',
      class: 'solr.TextField',
      positionIncrementGap: '100',
      indexAnalyzer: {
        tokenizer: { class: 'solr.StandardTokenizerFactory' },
        filters: [
          { class: 'solr.LowerCaseFilterFactory' },
          { class: 'solr.EdgeNGramFilterFactory', minGramSize: 1, maxGramSize: 20 }
        ]
      },
      queryAnalyzer: {
        tokenizer: { class: 'solr.StandardTokenizerFactory' },
        filters: [{ class: 'solr.LowerCaseFilterFactory' }]
      }
    }
    update_solr(conn, 'field-type', 'text_autocomplete', field_type_def)
  end

  def update_autocomplete_fields(conn)
    %w[name_ac email_ac bio_ac].each do |field|
      field_def = { name: field, type: 'text_autocomplete', stored: true, indexed: true }
      update_solr(conn, 'field', field, field_def)
    end
  end

  def update_standard_fields(conn)
    %w[name_text email_text bio_text].each do |field|
      field_def = { name: field, type: 'text_general', stored: true, indexed: true }
      update_solr(conn, 'field', field, field_def)
    end
  end

  def update_boolean_fields(conn)
    update_solr(conn, 'field', 'active_boolean',
                { name: 'active_boolean', type: 'boolean', stored: true, indexed: true })
  end

  def update_solr(conn, type, name, payload)
    conn.post 'schema', data: { "add-#{type}": payload }.to_json
    puts "Created #{type} '#{name}'."
  rescue RSolr::Error::Http => e
    raise e unless e.message.include?('already exists')

    puts "#{type.capitalize} '#{name}' exists. Replacing..."
    conn.post 'schema', data: { "replace-#{type}": payload }.to_json
    puts "Replaced #{type} '#{name}'."
  end
end
