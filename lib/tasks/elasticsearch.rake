namespace :elasticsearch do
  desc 'Reindex all searchable models'
  task reindex_all: :environment do
    puts 'Reindexing Microposts...'
    Micropost.reindex

    puts 'Reindexing Users...'
    User.reindex

    puts 'All models reindexed successfully!'
  end

  desc 'Reindex Microposts only'
  task reindex_microposts: :environment do
    puts 'Reindexing Microposts...'
    Micropost.reindex
    puts 'Microposts reindexed successfully!'
  end

  desc 'Reindex Users only'
  task reindex_users: :environment do
    puts 'Reindexing Users...'
    User.reindex
    puts 'Users reindexed successfully!'
  end
end
