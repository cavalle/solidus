# frozen_string_literal: true

module Spree
  module Admin
    class BaseController < Spree::BaseController
      helper 'spree/admin/navigation'
      layout '/spree/layouts/admin'

      before_action :authorize_admin

      private

      # Overrides ControllerHelpers::Common
      # We want the admin's locale selection to be different than that on the frontend
      def set_user_language_locale_key
        :admin_locale
      end

      def action
        params[:action].to_sym
      end

      def authorize_admin
        if respond_to?(:model_class, true) && model_class
          record = model_class
        else
          record = controller_name.to_sym
        end
        authorize! :admin, record
        authorize! action, record
      end

      # Need to generate an API key for a user due to some backend actions
      # requiring authentication to the Spree API
      def generate_admin_api_key
        if (user = try_spree_current_user) && user.spree_api_key.blank?
          user.generate_spree_api_key!
        end
      end

      def flash_message_for(object, event_sym)
        resource_desc  = object.class.model_name.human
        resource_desc += " \"#{object.name}\"" if object.respond_to?(:name) && object.name.present?
        t(event_sym, resource: resource_desc, scope: 'spree')
      end

      def render_js_for_destroy
        render partial: '/spree/admin/shared/destroy'
      end

      def config_locale
        Spree::Backend::Config[:locale]
      end

      def lock_order
        Spree::OrderMutex.with_lock!(@order) { yield }
      rescue Spree::OrderMutex::LockFailed
        flash[:error] = t('spree.order_mutex_admin_error')
        redirect_to order_mutex_redirect_path
      end

      def order_mutex_redirect_path
        edit_admin_order_path(@order)
      end

      def add_breadcrumb(name, path = nil)
        @admin_breadcrumbs ||= []
        @admin_breadcrumbs << [name, path]
      end

      # Shared breadcrumbs

      def set_user_breadcrumbs
        add_breadcrumb plural_resource_name(Spree::LegacyUser), spree.admin_users_path
        add_breadcrumb @user.email, edit_admin_user_url(@user) if @user && !@user.new_record?
      end

      def set_order_breadcrumbs
        add_breadcrumb plural_resource_name(Spree::Order), spree.admin_orders_path
        add_breadcrumb "##{@order.number}", spree.edit_admin_order_path(@order) if @order && !@order.new_record?
      end

      def set_product_breadcrumbs
        add_breadcrumb plural_resource_name(Spree::Product), spree.admin_products_path
        add_breadcrumb @product.name, spree.admin_product_path(@product) if @product && !@product.new_record?
      end
    end
  end
end
