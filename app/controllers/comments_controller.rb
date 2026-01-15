# frozen_string_literal: true

class CommentsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :logged_in_user
  before_action :set_micropost
  before_action :set_comment, only: [:update, :destroy]
  before_action :correct_user, only: [:update, :destroy]

  def index
    @comments = @micropost.comments.root_comments.includes(:user, :replies).recent
    render json: {
      success: true,
      comments: build_nested_comments(@comments),
      total_count: @micropost.comments_count
    }
  end

  def create
    @comment = @micropost.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      broadcast_comment(@comment, 'create')
      render json: {
        success: true,
        comment: comment_json(@comment),
        html: render_comment_html(@comment),
        total_count: @micropost.reload.comments_count
      }, status: :created
    else
      render json: { success: false, errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(comment_params.slice(:content))
      broadcast_comment(@comment, 'update')
      render json: {
        success: true,
        comment: comment_json(@comment),
        html: render_comment_html(@comment)
      }
    else
      render json: { success: false, errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    broadcast_comment(@comment, 'destroy')
    render json: {
      success: true,
      id: params[:id],
      total_count: @micropost.reload.comments_count
    }
  end

  private

  def set_micropost
    @micropost = Micropost.find(params[:micropost_id])
  end

  def set_comment
    @comment = @micropost.comments.find(params[:id])
  end

  def correct_user
    return if @comment.user_id == current_user.id || current_user.admin?

    render json: { success: false, error: 'Unauthorized' }, status: :forbidden
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      created_at: comment.created_at,
      time_ago: time_ago_in_words(comment.created_at),
      parent_id: comment.parent_id,
      reactions_count: comment.reactions_count,
      top_reactions: comment.reactions.group(:reaction_type).count.sort_by { |_, v| -v }.first(3).map(&:first),
      user: {
        id: comment.user.id,
        name: comment.user.name,
        gravatar_url: gravatar_url(comment.user)
      },
      user_reaction: current_user ? comment.reactions.find_by(user: current_user)&.reaction_type : nil
    }
  end

  def build_nested_comments(comments)
    comments.map do |comment|
      json = comment_json(comment)
      json[:replies] = build_nested_comments(comment.replies.recent) if comment.replies.any?
      json
    end
  end

  def gravatar_url(user, size: 40)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end

  def render_comment_html(comment)
    render_to_string(partial: 'comments/comment', locals: { comment: comment }, formats: [:html])
  end

  def broadcast_comment(comment, action)
    MicropostsChannel.broadcast_to(
      'feed',
      {
        action: "comment_#{action}",
        micropost_id: @micropost.id,
        comment: action != 'destroy' ? comment_json(comment) : nil,
        comment_id: comment.id,
        user_id: comment.user_id,
        html: action != 'destroy' ? render_comment_html(comment) : nil,
        total_count: @micropost.comments_count
      }
    )
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast comment: #{e.message}")
  end
end
