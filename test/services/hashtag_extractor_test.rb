require "test_helper"

class HashtagExtractorTest < ActiveSupport::TestCase
  test "should extract hashtags from content" do
    content = "This is a #test post with #ruby and #rails hashtags"
    hashtags = HashtagExtractor.extract_hashtags(content)
    
    assert_equal 3, hashtags.length
    assert_includes hashtags, "test"
    assert_includes hashtags, "ruby"
    assert_includes hashtags, "rails"
  end

  test "should extract unique hashtags" do
    content = "This has #test and #test again"
    hashtags = HashtagExtractor.extract_hashtags(content)
    
    assert_equal 1, hashtags.length
    assert_equal ["test"], hashtags
  end

  test "should return empty array when no hashtags" do
    content = "This has no hashtags"
    hashtags = HashtagExtractor.extract_hashtags(content)
    
    assert_equal 0, hashtags.length
  end

  test "should create hashtag records and associate with micropost" do
    user = users(:michael)
    micropost = Micropost.create!(
      user: user,
      content: "Testing #ruby and #rails"
    )

    assert_equal 2, micropost.hashtags.count
    assert_equal ["rails", "ruby"], micropost.hashtags.pluck(:name).sort
  end

  test "should not create duplicate hashtags" do
    user = users(:michael)
    
    # Create first micropost with hashtag
    micropost1 = Micropost.create!(
      user: user,
      content: "First post with #ruby"
    )
    
    initial_count = Hashtag.count
    
    # Create second micropost with same hashtag
    micropost2 = Micropost.create!(
      user: user,
      content: "Second post with #ruby"
    )
    
    # Should not create new hashtag
    assert_equal initial_count, Hashtag.count
    
    # Both microposts should share the same hashtag
    assert_equal micropost1.hashtags.first, micropost2.hashtags.first
  end
end
