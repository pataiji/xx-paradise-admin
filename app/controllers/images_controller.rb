class ImagesController < ApplicationController
  def new
    @image = Image.new
  end

  def create
    @image = Image.new(create_params)
    if @image.save
      redirect_to new_image_url
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:image).permit(:data)
  end
end
