# frozen_string_literal: true

class StatisticsIndex
  attr_reader :frame

  # 初期化
  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new
  end

  # UIの初期化
  def initialize_ui(id)

  end

end
