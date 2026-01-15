class LikesController < ApplicationController
    before_action :logged_in_user
    before_action :set_micropost

    # GET /microposts/:id/likes
    def index
        @likers = @micropost.liked_by_users.limit(500)
        # Force rendering the partial as HTML even when request.format == :json
        html = render_to_string(partial: 'likes/list', locals: { likers: @likers }, formats: [:html])
        render json: { html: html }
    rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def create
        if @micropost.liked_by?(current_user)
            render json: { error: 'Already liked' }, status: :unprocessable_entity
            return
        end

        @micropost.like!(current_user)

        render json: {
            liked: true,
            likes_count: @micropost.likes_count
            }, status: :created
        rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
        unless @micropost.liked_by?(current_user)
            render json: { error: 'Not liked yet' }, status: :unprocessable_entity
            return
        end

        @micropost.unlike!(current_user)

        render json: {
            liked: false,
            likes_count: @micropost.likes_count
            }, status: :ok
        rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    private
        def set_micropost
            @micropost = Micropost.find(params[:id])
            rescue ActiveRecord::RecordNotFound
                render json: { error: 'Micropost not found' }, status: :not_found
        end
end
