class PlotElements
  attr_reader :plot

  def initialize(plot:)
    @plot = plot
  end

  def outdated
    @outdated ||= begin
      plot_elements = plot.plot_elements.includes(element: :latest_revision).to_a
      plot_elements.filter_map do |pe|
        latest_revision = pe.element.latest_revision
        next if pe.element_revision_id == latest_revision.id

        { plot_element: pe, latest_revision: latest_revision }
      end
    end
  end
end
