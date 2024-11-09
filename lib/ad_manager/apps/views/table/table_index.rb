# frozen_string_literal: true

class TableIndex
  attr_reader :frame

  def initialize(window, stack)
    @window = window
    @stack = stack
    @frame = Gtk::Frame.new

    set_ui
    set_signal_connect

  end

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    
  end

  def set_signal_connect

  end

  def initialize_ui(id)

  end

end
