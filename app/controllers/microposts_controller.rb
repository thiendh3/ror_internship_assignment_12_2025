# frozen_string_literal: true

class MicropostsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :logged_in_user, only: %i[create destroy update share]
  before_action :correct_user, only: %i[destroy update]
  before_action :set_micropost, only: %i[show share]

  def show
    @micropost = Micropost.find(params[:id])

    # Check visibility: private posts can only be viewed by owner
    unless @micropost.public? || (logged_in? && current_user.id == @micropost.user_id)
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false }
        format.json { render json: { error: 'Post not found' }, status: :not_found }
      end
      return
    end

    # Redirect to user profile with anchor instead of showing separate page
    respond_to do |format|
      format.html { redirect_to user_path(@micropost.user, anchor: "micropost-#{@micropost.id}") }
      format.json do
        # Only owner can see edit history
        include_versions = logged_in? && current_user.id == @micropost.user_id
        render json: micropost_json(@micropost, include_versions: include_versions)
      end
    end
  end

  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?

    if @micropost.save
      handle_create_success
    else
      handle_create_failure
    end
  end

  def update
    if @micropost.update(micropost_params)
      handle_update_success
    else
      handle_update_failure
    end
  end

  def destroy
    @micropost.destroy
    broadcast_micropost(@micropost, 'destroy')

    respond_to do |format|
      format.html do
        flash[:success] = 'Micropost is deleted'
        redirect_to request.referrer || root_url
      end
      format.json { render json: { success: true, id: params[:id] } }
    end
  end

  # Share a post - creates a new micropost with original_post_id
  def share
    original = @micropost.root_post # Always share the root post

    shared_post = current_user.microposts.build(
      content: params[:content].presence || '',
      original_post_id: original.id
    )

    if shared_post.save
      # Update shares_count on original
      original.increment!(:shares_count)

      # Notify original post owner
      notify_share(original, shared_post) if original.user_id != current_user.id

      broadcast_micropost(shared_post, 'create')

      render json: {
        success: true,
        micropost: micropost_json(shared_post),
        html: render_micropost_html(shared_post),
        redirect_url: user_path(current_user, anchor: "micropost-#{shared_post.id}")
      }, status: :created
    else
      render json: { success: false, errors: shared_post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def handle_create_success
    broadcast_micropost(@micropost, 'create')
    respond_to do |format|
      format.html do
        flash[:success] = 'Micropost created!'
        redirect_to root_url
      end
      format.json do
        render json: {
          success: true,
          micropost: micropost_json(@micropost),
          html: render_micropost_html(@micropost)
        }, status: :created
      end
    end
  end

  def handle_create_failure
    respond_to do |format|
      format.html do
        @feed_items = current_user.feed.paginate(page: params[:page])
        render 'static_pages/home'
      end
      format.json do
        render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def handle_update_success
    broadcast_micropost(@micropost, 'update')
    respond_to do |format|
      format.html do
        flash[:success] = 'Micropost updated!'
        redirect_to root_url
      end
      format.json do
        image_url = @micropost.image.attached? ? @micropost.display_image : nil
        render json: {
          success: true,
          micropost: micropost_json(@micropost),
          html: render_micropost_html(@micropost),
          image_url: image_url
        }
      end
    end
  end

  def handle_update_failure
    respond_to do |format|
      format.html { redirect_to root_url, alert: 'Failed to update micropost' }
      format.json do
        render json: { error: @micropost.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end
  end

  def notify_share(original, shared_post)
    Notification.create!(
      user: original.user,
      notifiable: shared_post,
      notification_type: 'share'
    )
  rescue StandardError => e
    Rails.logger.error("Failed to notify share: #{e.message}")
  end

  def micropost_params
    params.require(:micropost).permit(:content, :image, :visibility)
  end

  def set_micropost
    @micropost = Micropost.find_by(id: params[:id])
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    return if @micropost.present?

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: { success: false, error: 'Unauthorized' }, status: :forbidden }
    end
  end

  def micropost_json(micropost, include_versions: false)
    result = {
      id: micropost.id,
      content: micropost.content,
      created_at: micropost.created_at,
      updated_at: micropost.updated_at,
      time_ago: time_ago_in_words(micropost.created_at),
      edited: micropost.updated_at > micropost.created_at,
      user: micropost_user_json(micropost.user),
      image_url: micropost.image.attached? ? url_for(micropost.display_image) : nil
    }

    result[:versions] = micropost_versions_json(micropost) if include_versions && micropost.versions.any?
    result
  end

  def micropost_user_json(user)
    {
      id: user.id,
      name: user.name,
      gravatar_url: gravatar_url(user)
    }
  end

  def micropost_versions_json(micropost)
    micropost.versions.map do |v|
      {
        content: v.content,
        edited_at: v.edited_at,
        time_ago: time_ago_in_words(v.edited_at)
      }
    end
  end

  def gravatar_url(user, size: 50)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end

  def render_micropost_html(micropost)
    render_to_string(partial: 'microposts/micropost', locals: { micropost: micropost }, formats: [:html])
  end

  def broadcast_micropost(micropost, action)
    # Only broadcast public posts to feed
    # Private posts should not appear in other users' feeds
    return if action == 'create' && micropost.private?

    MicropostsChannel.broadcast_to(
      'feed',
      {
        action: action,
        micropost: micropost_json(micropost),
        html: action == 'destroy' ? nil : render_micropost_html(micropost),
        micropost_id: micropost.id,
        user_id: micropost.user_id,
        visibility: micropost.visibility
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast micropost: #{e.message}")
  end
end
