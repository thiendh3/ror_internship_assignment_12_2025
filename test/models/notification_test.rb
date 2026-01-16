# frozen_string_literal: true

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    @other_user = users(:archer)
  end

  test 'should be valid with required attributes' do
    relationship = Relationship.create!(follower: @other_user, followed: @user)
    notification = Notification.new(
      user: @user,
      notifiable: relationship,
      notification_type: 'follow'
    )
    assert notification.valid?
    relationship.destroy
  end

  test 'should require notification_type' do
    notification = Notification.new(user: @user, notifiable_type: 'Relationship', notifiable_id: 1)
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "can't be blank"
  end

  test 'actor returns follower for follow notification' do
    relationship = Relationship.create!(follower: @other_user, followed: @user)
    notification = Notification.create!(
      user: @user,
      notifiable: relationship,
      notification_type: 'follow'
    )
    assert_equal @other_user, notification.actor
    relationship.destroy
  end

  test 'actor returns nil when notifiable is nil' do
    notification = Notification.new(
      user: @user,
      notifiable: nil,
      notification_type: 'follow'
    )
    assert_nil notification.actor
  end

  test 'unread scope returns only unread notifications' do
    relationship = Relationship.create!(follower: @other_user, followed: @user)
    unread = Notification.create!(user: @user, notifiable: relationship, notification_type: 'follow', read: false)
    read = Notification.create!(user: @user, notifiable: relationship, notification_type: 'follow', read: true)

    assert_includes @user.notifications.unread, unread
    assert_not_includes @user.notifications.unread, read
    relationship.destroy
  end
end
