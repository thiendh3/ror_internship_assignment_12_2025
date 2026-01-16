# frozen_string_literal: true

require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other_user = users(:archer)
  end

  test 'should redirect index when not logged in' do
    get notifications_path
    assert_redirected_to login_url
  end

  test 'should get index when logged in' do
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    get notifications_path
    assert_response :success
  end

  test 'should get unread_count when logged in' do
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    get unread_count_notifications_path, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, 'count'
  end

  test 'mark_as_read should mark notification and redirect' do
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    relationship = Relationship.create!(follower: @other_user, followed: @user)
    notification = Notification.create!(
      user: @user,
      notifiable: relationship,
      notification_type: 'follow',
      read: false
    )

    post mark_as_read_notification_path(notification)
    assert notification.reload.read
    assert_redirected_to user_path(@other_user)

    relationship.destroy
  end

  test 'mark_all_as_read should mark all notifications' do
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    relationship = Relationship.create!(follower: @other_user, followed: @user)
    Notification.create!(user: @user, notifiable: relationship, notification_type: 'follow', read: false)
    Notification.create!(user: @user, notifiable: relationship, notification_type: 'follow', read: false)

    post mark_all_as_read_notifications_path
    assert_equal 0, @user.notifications.unread.count

    relationship.destroy
  end
end
