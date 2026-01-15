require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  def setup
    @liker = users(:archer)
    @commenter = users(:archer)
    @micropost = microposts(:orange)
    @micropost_owner = @micropost.user
  end

  test "create_like_notification should create notification" do
    assert_difference 'Notification.count', 1 do
      NotificationService.create_like_notification(@liker, @micropost)
    end

    notification = Notification.last
    assert_equal @micropost_owner, notification.recipient
    assert_equal @liker, notification.actor
    assert_equal 'liked', notification.action
  end

  test "create_like_notification should not create notification for own micropost" do
    assert_no_difference 'Notification.count' do
      NotificationService.create_like_notification(@micropost_owner, @micropost)
    end
  end

  test "create_comment_notification should create notification" do
    comment = Comment.create!(
      user: @commenter,
      micropost: @micropost,
      content: "Great post!"
    )

    # Note: notification is created by callback, so we check it exists
    notification = Notification.where(
      recipient: @micropost_owner,
      actor: @commenter,
      action: 'commented'
    ).last

    assert_not_nil notification
    assert_equal @micropost_owner, notification.recipient
    assert_equal @commenter, notification.actor
  end

  test "create_mention_notification should create notification" do
    mentioned_user = users(:lana)
    mentioner = users(:archer)
    
    # Create micropost with mention using first name only (since MENTION_REGEX only captures \w+)
    # User.find_by(name:) will try to match "Lana" but user.name is "Lana Kane"
    # Better to use a user with single word name or test the direct service call
    
    micropost = Micropost.create!(
      user: mentioner,
      content: "Hey @michael check this out"
    )

    notification = Notification.where(
      recipient: users(:michael),
      actor: mentioner,
      action: 'mentioned'
    ).last

    assert_not_nil notification
    assert_equal users(:michael), notification.recipient
    assert_equal mentioner, notification.actor
  end
end
