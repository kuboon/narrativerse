class HomeController < ApplicationController
  def index
    @plots = Plot.order(created_at: :desc).limit(12)
    @elements = Element.order(created_at: :desc).limit(12)
    @plot_count = Plot.count
    @element_count = Element.count
  end
end
