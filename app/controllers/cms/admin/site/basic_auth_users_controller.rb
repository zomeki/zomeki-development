# encoding: utf-8
class Cms::Admin::Site::BasicAuthUsersController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    @site = Cms::Site.find(params[:site])
  end

  def index
    @items = Cms::SiteBasicAuthUser.where(site_id: Core.site.id).paginate(page: params[:page], per_page: params[:limit])
    _index @items
  end

  def show
    @item = Cms::SiteBasicAuthUser.new.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Cms::SiteBasicAuthUser.new({
      :site_id    => @site.id,
      :state      => 'enabled',
    })
  end

  def create
    @item = Cms::SiteBasicAuthUser.new(params[:item])
    @item.site_id = @site.id
    _create @item do
    end
  end

  def update
    @item = Cms::SiteBasicAuthUser.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item do
    end
  end

  def destroy
    @item = Cms::SiteBasicAuthUser.new.find(params[:id])
    _destroy(@item) do
    end
  end

  def enable_auth
    @site.enable_basic_auth

    flash[:notice] = "Basic認証を有効にしました。"
    redirect_to cms_site_basic_auth_users_path(@site.id)
  end

  def disable_auth
    @site.disable_basic_auth

    flash[:notice] = "Basic認証を無効にしました。"
    redirect_to cms_site_basic_auth_users_path(@site.id)
  end
end
