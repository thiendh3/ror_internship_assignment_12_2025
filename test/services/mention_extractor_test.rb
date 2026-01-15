require 'test_helper'

class MentionExtractorTest < ActiveSupport::TestCase
  test 'should extract mentions from content' do
    content = 'Hey @michael and @archer, check this out!'
    mentions = MentionExtractor.extract_mentions(content)

    assert_equal 2, mentions.length
    assert_includes mentions, 'michael'
    assert_includes mentions, 'archer'
  end

  test 'should extract unique mentions' do
    content = 'Hey @michael and @michael again'
    mentions = MentionExtractor.extract_mentions(content)

    assert_equal 1, mentions.length
    assert_equal ['michael'], mentions
  end

  test 'should return empty array when no mentions' do
    content = 'This has no mentions'
    mentions = MentionExtractor.extract_mentions(content)

    assert_equal 0, mentions.length
  end
end
