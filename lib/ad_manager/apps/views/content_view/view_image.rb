# frozen_string_literal: true

require 'gtk3'

class ViewImage < Gtk::Dialog

  def initialize(parent, img)
    super(title: I18n.t('image.title'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(700, 900)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @img = img
    @img_path = './files/akiba_images/'

    set_ui
    set_signal_connect

    show_all
  end

  private

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box)

    @image = Gtk::Image.new
    @image.set_size_request(650, 850)
    h_box.pack_start(@image, expand: true)

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 10)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(140, 50)
    btn_box.pack_start(@close_btn, expand: true)

    file_path = "#{@img_path}#{@img.file_name}"
    img = GdkPixbuf::Pixbuf.new(file: file_path)

    set_image(img)
  end

  def set_signal_connect
    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::OK)
      destroy
    end
  end

  def set_image(pixbuf)
    return if pixbuf.nil?

    new_width = 650
    new_height = 850

    original_width = pixbuf.width
    original_height = pixbuf.height

    width_ratio = new_width.to_f / original_width
    height_ratio = new_height.to_f / original_height

    if width_ratio < height_ratio
      new_width = original_width * width_ratio
      new_height = original_height * width_ratio
    else
      new_width = original_width * height_ratio
      new_height = original_height * height_ratio
    end

    scaled_pixbuf = pixbuf.scale_simple( new_width.round, new_height.round, GdkPixbuf::InterpType::BILINEAR )

    @image.set_from_pixbuf(scaled_pixbuf)
  end

end
