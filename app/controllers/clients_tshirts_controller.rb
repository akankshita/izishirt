class ClientsTshirtsController < ApplicationController

  def photos
    @client_photos = ClientPhoto.paginate(:page=>params[:page], :per_page=>10, :order=>"id DESC")
    @meta_title = t(:client_photos_listing_title)
    @meta_description = t(:client_photos_listing_description)
  end

  def photo_detail
    id = StringUtil.get_id_from_url(params[:id])
    @client_photo = ClientPhoto.find(id, :include=>:store_comments)
    @comments = @client_photo.store_comments
    @meta_title = t(:client_photos_details_title, :title=>@client_photo.title)
    @meta_description = t(:client_photos_details_description, :title=>@client_photo.title)
  end
  
end
