class ApplicationController < ActionController::Base
  before_action :redirect_to_domain
  helper_method :is_cloudfront?

  def default_url_options
    Rails.application.routes.default_url_options
  end

  def is_cloudfront?
    request.headers['X-Cloudfront-Secret'] == ENV['CLOUDFRONT_SECRET']
  end

  def redirect_to_domain
    # Prevent people from bypassing CloudFront and hitting Heroku directly.
    if Rails.env.production? && !is_cloudfront?
      protocol = Rails.configuration.force_ssl ? 'https' : 'http'
      redirect_to "#{protocol}://#{Rails.application.routes.default_url_options[:host]}#{request.fullpath}", status: 301
    end
  end

  private

  def no_cache
    expires_now
  end

  def set_max_age(seconds: ENV['CONFIG_CACHE_TTL'])
    response.headers['Cache-Control'] = "s-maxage=#{seconds}, max-age=0, public"
  end
end
