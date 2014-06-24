require 'charter/gruff_themes'

module Charter
  class ChartBase
    attr_accessor :title, :data, :columns, :label_column

    # data: array of hash
    # [{date: 2013-1-2, hours_remain: 2, estimated_hours_remain: 10},
    # {date: 2013-1-3, hours_remain: 4, estimated_hours_remain: 10},
    # {date: 2013-1-4, hours_remain: 10, estimated_hours_remain: 10}]

    def initialize
      columns, data = [], []
    end

    def add_row(row)
      data << row
    end

    def render_chart(html_dom_id, options = {})
      api_name = options[:web_api_name] || Charter.config.web_api_name.to_s
      class_name = self.class.name.split("::")[1]
      load "charter/web_chart/#{api_name}/#{class_name.underscore}.rb"
      chart = "Charter::WebChart::#{api_name.camelize}::#{class_name}".constantize.new
      chart.data, chart.columns, chart.label_column = self.data, self.columns, self.label_column
      html = <<-HTML
      <script type="application/javascript" class="chart_script">
        #{chart.render(html_dom_id)}
      </script>
      HTML
      html.html_safe
    end

    def self.evaluate_js
      "eval($('script.chart_script').text());"
    end

    protected
    def prepare_gruff(type)
      chart_type = type.to_s.classify
      chart_type = "Gruff::#{chart_type}".constantize

      g = chart_type.new
      g.theme = Charter::Themes::GOOGLE_CHART
      g.title = self.title
      g
    end

    def data_for_column(column_name)
      data.map { |row| row[column_name] }
    end

    def column_names
      @column_names ||= begin
        columns.collect do |column|
          column.kind_of?(Array) ? column[1] : column.to_s.humanize
        end
      end
    end

    def column_keys
      @column_keys ||= begin
        columns.collect do |column|
          column.kind_of?(Array) ? column[0] : column
        end
      end
    end

    def text_color
      web_config.text_color
    end

    def baseline_color
      text_color
    end

    def grid_color
      text_color
    end

    def bg_color
      web_config.background_color
    end

    def web_colors
      web_config.colors
    end

    # Amount should be a decimal between 0 and 1. Lower means darker
    def darken_color(hex_color, amount=0.4)
      hex_color = hex_color.gsub('#','')
      rgb = hex_color.scan(/../).map {|color| color.hex}
      rgb[0] = (rgb[0].to_i * amount).round
      rgb[1] = (rgb[1].to_i * amount).round
      rgb[2] = (rgb[2].to_i * amount).round
      "#%02x%02x%02x" % rgb
    end

    # Amount should be a decimal between 0 and 1. Higher means lighter
    def lighten_color(hex_color, amount=0.6)
      hex_color = hex_color.gsub('#','')
      rgb = hex_color.scan(/../).map {|color| color.hex}
      rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
      rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
      rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
      "#%02x%02x%02x" % rgb
    end

    def config
      @config ||= Charter.config
    end

    def web_config
      @web_config ||= Charter.config.web_config
    end
  end
end