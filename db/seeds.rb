# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting seed..."

# Clear existing data (optional - comment out if you want to keep existing data)
puts "Clearing existing data..."
Comment.destroy_all
Like.destroy_all
Notification.destroy_all
MicropostHashtag.destroy_all
Hashtag.destroy_all
Micropost.destroy_all
Relationship.destroy_all
User.destroy_all

puts "Creating main admin user..."
# Create a main admin user
admin = User.create!(
  name: "admin",
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  admin: true,
  activated: true,
  activated_at: Time.zone.now
)

puts "Creating 20-30 users with random activation status..."
# Generate 20-30 additional users with random activation status
users_count = rand(20..30)
users_count.times do |n|
  # Random activation status (80% activated, 20% not activated)
  is_activated = rand < 0.8
  
  User.create!(
    name: Faker::Internet.username(specifier: 3..15, separators: []),
    email: Faker::Internet.unique.email,
    password: "password",
    password_confirmation: "password",
    admin: false,
    activated: is_activated,
    activated_at: is_activated ? Faker::Time.between(from: 30.days.ago, to: Time.zone.now) : nil
  )
end

# Get all activated users for creating content
activated_users = User.where(activated: true)

puts "Creating microposts with hashtags and mentions..."
# Create microposts with various content types
content_templates = [
  "Just finished a great project! #rails #ruby #coding",
  "Learning something new every day #webdev #programming",
  "Coffee and code ☕ #developer #life",
  "Check out this awesome tutorial #learning #tech",
  "Working on a new feature #excited #development",
  "Happy #{['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].sample}! #motivation",
  "Deploying to production... wish me luck! #devops #deployment",
  "Code review time #teamwork #quality",
  "Finally fixed that bug! 🎉 #victory #debugging",
  "Reading about #docker and #kubernetes today",
]

activated_users.each do |user|
  # Each user creates 3-8 microposts
  microposts_count = rand(3..8)
  
  microposts_count.times do
    # Choose random privacy setting
    privacy = [:public_post, :followers_only, :private_post].sample
    
    # 70% use template, 30% short random
    if rand < 0.7
      content = content_templates.sample
    else
      content = Faker::Lorem.sentence(word_count: rand(5..10))
      # Add 1-2 random hashtags (keep it short)
      rand(1..2).times do
        content += " ##{['ruby', 'rails', 'coding', 'webdev', 'tech'].sample}"
      end
    end
    
    # Ensure content is under 140 characters
    content = content[0..139] if content.length > 140
    
    # Add random mention (20% chance, only if room)
    if rand < 0.2 && activated_users.count > 1 && content.length < 120
      mentioned_user = (activated_users - [user]).sample
      mention_text = " @#{mentioned_user.name}"
      if (content.length + mention_text.length) <= 140
        content += mention_text
      end
    end
    
    user.microposts.create!(
      content: content,
      privacy: privacy,
      created_at: Faker::Time.between(from: 30.days.ago, to: Time.zone.now)
    )
  end
end

puts "Creating follower relationships..."
# Create following relationships
activated_users.each do |user|
  # Each user follows 3-10 random other users
  following_count = rand(3..10)
  other_users = (activated_users - [user]).sample(following_count)
  
  other_users.each do |followed|
    user.follow(followed) unless user.following?(followed)
  end
end

puts "Creating likes on microposts..."
# Create likes (each user likes 5-15 random microposts)
activated_users.each do |user|
  microposts = Micropost.where.not(user: user).sample(rand(5..15))
  
  microposts.each do |micropost|
    Like.create(user: user, micropost: micropost) unless micropost.liked_by?(user)
  end
end

puts "Creating comments on microposts..."
# Create comments (each user comments on 3-10 random microposts)
comment_templates = [
  "Great post!",
  "Thanks for sharing!",
  "Interesting perspective",
  "I agree with this",
  "This is helpful",
  "Nice work!",
  "Love it! 👍",
  "Can you explain more?",
  "This helped me a lot",
  "Keep it up!"
]

activated_users.each do |user|
  microposts = Micropost.where.not(user: user).sample(rand(3..10))
  
  microposts.each do |micropost|
    content = comment_templates.sample
    Comment.create!(
      user: user,
      micropost: micropost,
      content: content,
      created_at: Faker::Time.between(from: micropost.created_at, to: Time.zone.now)
    )
  end
end

puts "✅ Seed completed!"
puts "📊 Summary:"
puts "  - Total users: #{User.count} (#{User.where(activated: true).count} activated)"
puts "  - Total microposts: #{Micropost.count}"
puts "  - Total hashtags: #{Hashtag.count}"
puts "  - Total relationships: #{Relationship.count}"
puts "  - Total likes: #{Like.count}"
puts "  - Total comments: #{Comment.count}"
puts "  - Total notifications: #{Notification.count}"
puts ""
puts "🔐 Admin credentials:"
puts "  Email: admin@example.com"
puts "  Password: password"
