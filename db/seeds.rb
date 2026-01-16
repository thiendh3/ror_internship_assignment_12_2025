# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

#Create a main sample user
User.create!(name: "Tian Dn",
            email: "thiendoan99999@gmail.com",
            password: "password",
            password_confirmation: "password",
            admin: true,
            activated: true,
            activated_at: Time.zone.now)

#Generate a bunch of additional users
99.times do |n|
  name = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.create!(name: name, email: email, password: password,
              password_confirmation: password, activated: true,
              activated_at: Time.zone.now)
end

#Generate microposts for some users
users = User.order(:created_at).take(6)
hashtags = %w[rails ruby solr search tutorial]

50.times do
  sentence = Faker::Lorem.sentence(word_count: 4)

  tag_string = hashtags.sample(rand(1..2))
                         .map { |t| "##{t}" }
                         .join(" ")

  content = "#{sentence} #{tag_string}"

  users.each do |user|
    Micropost.create!(
      user: user,
      content: content
    )
  end
end

#Create following relationships
users = User.all
user = users.first
following = users[2..50]
followers = users[3..40]
following.each {|followed| user.follow(followed)}
followers.each {|follower| follower.follow(user)}

#Create reactions for microposts
microposts = Micropost.all
reaction_types = [:like, :love, :haha]

microposts.each do |micropost|
  # Random number of reactions (0-15) for each micropost
  rand(0..15).times do
    random_user = users.sample
    random_reaction = reaction_types.sample
    
    # Only create if user hasn't already reacted to this post
    unless Like.exists?(user: random_user, micropost: micropost)
      Like.create!(
        user: random_user,
        micropost: micropost,
        reaction_type: random_reaction
      )
    end
  end
end

puts "Created #{User.count} users"
puts "Created #{Micropost.count} microposts"
puts "Created #{Relationship.count} relationships"
puts "Created #{Like.count} reactions"
