require 'test_helper'

class FollowNotificationsTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:lana) # Use lana to avoid duplicate relationship issues
  end

  test 'following a user creates a notification' do
    log_in_as(@user)

    assert_difference 'Notification.count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }
    end

    notification = Notification.last
    assert_equal @other_user, notification.recipient
    assert_equal @user, notification.actor
    assert_equal 'followed', notification.action
  end

  test 'notification is created with correct message' do
    log_in_as(@user)
    post relationships_path, params: { followed_id: @other_user.id }

    notification = Notification.last
    assert_includes notification.message, 'started following you'
  end

  test 'notification recipient receives the notification' do
    log_in_as(@user)
    initial_notifications = @other_user.notifications.count

    post relationships_path, params: { followed_id: @other_user.id }

    assert_equal initial_notifications + 1, @other_user.notifications.count
  end

  test 'notification is unread by default' do
    log_in_as(@user)
    post relationships_path, params: { followed_id: @other_user.id }

    notification = Notification.last
    assert_not notification.read
  end

  test 'duplicate follow does not create duplicate notification' do
    log_in_as(@user)
    @user.follow(@other_user)
    NotificationService.create_follow_notification(@user, @other_user)

    assert_no_difference 'Notification.count' do
      NotificationService.create_follow_notification(@user, @other_user)
    end
  end

  test 'unfollowing does not create notification by default' do
    log_in_as(@user)
    @user.follow(@other_user)
    relationship = @user.active_relationships.find_by(followed_id: @other_user.id)

    # Count notifications before unfollow
    initial_notifications = Notification.count

    delete relationship_path(relationship)

    # Should not create notification (unfollow notifications are optional)
    assert_equal initial_notifications, Notification.count
  end

  test 'notification includes notifiable reference to user' do
    log_in_as(@user)
    post relationships_path, params: { followed_id: @other_user.id }

    notification = Notification.last
    assert_equal 'User', notification.notifiable_type
    assert_equal @other_user.id, notification.notifiable_id
    assert_equal @other_user, notification.notifiable
  end

  test 'user can see their follow notifications' do
    log_in_as(@other_user)

    # Another user follows this user
    @user.follow(@other_user)
    NotificationService.create_follow_notification(@user, @other_user)

    get notifications_path, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert(json_response['notifications'].any? { |n| n['action'] == 'followed' })
  end
end
