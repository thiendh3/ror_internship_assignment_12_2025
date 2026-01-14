namespace :solr do
  desc "Robust Configure Solr Schema (Force Update Types)"
  task setup: :environment do
    conn = SolrService.connection
    puts "Configuring Solr Schema..."

    # 1. Define 'text_autocomplete' Field Type (With Force Update)
    field_type_def = {
      "name": "text_autocomplete",
      "class": "solr.TextField",
      "positionIncrementGap": "100",
      "analyzer": {
        "tokenizer": { "class": "solr.StandardTokenizerFactory" },
        "filters": [{ "class": "solr.LowerCaseFilterFactory" }]
      },
      "indexAnalyzer": {
        "tokenizer": { "class": "solr.StandardTokenizerFactory" },
        "filters": [
          { "class": "solr.LowerCaseFilterFactory" },
          { 
            "class": "solr.EdgeNGramFilterFactory", 
            "minGramSize": "1", 
            "maxGramSize": "20" 
          }
        ]
      },
      "queryAnalyzer": {
        "tokenizer": { "class": "solr.StandardTokenizerFactory" },
        "filters": [{ "class": "solr.LowerCaseFilterFactory" }]
      }
    }

    begin
      conn.post 'schema', data: { "add-field-type": field_type_def }.to_json, headers: { 'Content-Type' => 'application/json' }
      puts "Created Field Type 'text_autocomplete'."
    rescue RSolr::Error::Http => e
      if e.message.include?("already exists")
        # THIS IS THE MISSING PART: Force Update!
        puts "Field Type 'text_autocomplete' exists. Updating..."
        conn.post 'schema', data: { "replace-field-type": field_type_def }.to_json, headers: { 'Content-Type' => 'application/json' }
        puts "Updated Field Type 'text_autocomplete'."
      end
    end

    # 2. Configure Autocomplete Fields (Add or Replace)
    ac_fields = ["name_ac", "email_ac", "bio_ac"]
    
    ac_fields.each do |field|
      field_def = { "name": field, "type": "text_autocomplete", "stored": true, "indexed": true }

      begin
        conn.post 'schema', data: { "add-field": field_def }.to_json, headers: { 'Content-Type' => 'application/json' }
        puts "Created field '#{field}'."
      rescue RSolr::Error::Http => e
        if e.message.include?("already exists")
          puts "Field '#{field}' exists. Updating..."
          conn.post 'schema', data: { "replace-field": field_def }.to_json, headers: { 'Content-Type' => 'application/json' }
          puts "Updated field '#{field}'."
        end
      end
    end

    # 3. Configure Standard Fields
    text_fields = ["name_text", "email_text", "bio_text"]
    text_fields.each do |field|
      field_def = { "name": field, "type": "text_general", "stored": true, "indexed": true }
      begin
        conn.post 'schema', data: { "add-field": field_def }.to_json, headers: { 'Content-Type' => 'application/json' }
      rescue RSolr::Error::Http; end
    end

    # 4. Configure Boolean Field
    begin
      conn.post 'schema', data: { "add-field": { "name": "active_boolean", "type": "boolean", "stored": true, "indexed": true } }.to_json, headers: { 'Content-Type' => 'application/json' }
    rescue RSolr::Error::Http; end

    puts "Schema setup complete."
  end
end