require 'digest/sha1'
class AffiliatesController < ApplicationController
  
  def index
    detect_affiliate
     
  end
  
  private

  def detect_affiliate
    cookie_hash = Hash.new
    redirection = @URL_ROOT
    if params[AFFILIATE_PATH_PARAM] && ! params[AFFILIATE_PATH_PARAM].empty?
      cookie_hash[AFFILIATE_PATH_PARAM] = params[AFFILIATE_PATH_PARAM]
      redirection += "/" + session[:language]
      redirection += "/" if params[AFFILIATE_PATH_PARAM].first != "/"
      redirection += params[AFFILIATE_PATH_PARAM]
    end
    if !params[AFFILIATES_SPACE_PARAM] || !params[AFFILIATE_ID_PARAM]
      redirect_to redirection
      return
    end
    
    
    cookie_hash[AFFILIATES_SPACE_PARAM] = params[AFFILIATES_SPACE_PARAM]
    cookie_hash[AFFILIATE_ID_PARAM] = params[AFFILIATE_ID_PARAM]
    
    cookie_hash[AFFILIATE_REFERRER_PARAM] = request.referrer
    cookie_hash[AFFILIATE_EXPIRY_DATE] = 3.months.from_now
    to_hash = cookie_hash[AFFILIATES_SPACE_PARAM]+cookie_hash[AFFILIATE_ID_PARAM]+cookie_hash[AFFILIATE_REFERRER_PARAM]
    to_hash += cookie_hash[AFFILIATE_PATH_PARAM] if cookie_hash[AFFILIATE_PATH_PARAM] && !cookie_hash[AFFILIATE_PATH_PARAM].empty?
    to_hash += cookie_hash[AFFILIATE_EXPIRY_DATE].to_s + SALT_AFFILIATE_COOKIE
    cookie_hash[CHECK_COOKIE] = Digest::SHA1.hexdigest(to_hash)

    cookies[AFFILIATES_COOKIE] = {
      :value => Marshal.dump(cookie_hash), :expires => cookie_hash[AFFILIATE_EXPIRY_DATE] }

    url = CONNEXPLACE_ENTRY_URL
    if (ENV['RAILS_ENV'] == "production")
      url += "?"
    else
      url += "&"
    end
    url += AFFILIATES_SPACE_PARAM + "=" + cookie_hash[AFFILIATES_SPACE_PARAM]
    url += "&" + AFFILIATE_ID_PARAM + "=" + cookie_hash[AFFILIATE_ID_PARAM]
    url += "&" + AFFILIATE_REFERRER_PARAM + "=" + cookie_hash[AFFILIATE_REFERRER_PARAM]
    url += "&" + IP_PARAM  + "=" + request.ip

    Thread.new{
      Net::HTTP.get(URI.parse(url))
    }
    redirect_to redirection
  end
end
