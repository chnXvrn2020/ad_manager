# frozen_string_literal: true

require 'gtk3'

require_relative '../../../controllers/file_controller'

class ImageEdit < Gtk::Dialog

  attr_reader :img, :file_name, :img_del

  def initialize(parent, type, id = nil, img = nil, del = nil)
    super(title: I18n.t('image.title'), parent: parent,
          flags: %i[modal destroy_with_parent])
    set_size_request(500, 700)
    set_position(Gtk::WindowPosition::CENTER)

    self.deletable = false
    self.resizable = false

    @parent = parent
    @type = type
    @id = id
    @img = img
    @file_name = nil
    @img_frame = nil
    @changed = false
    @img_del = del
    @controller = FileController.new
    @img_path = './files/akiba_images/'
    @no_image = './assets/images/no_image_tate.jpg'

    set_ui
    set_signal_connect

    show_all
  end

  def set_ui
    h_box = Gtk::Box.new(:horizontal)
    child.pack_start(h_box)

    @image = Gtk::Image.new
    @image.set_size_request(500, 650)
    h_box.pack_start(@image, expand: true)

    if @img.nil?
      img = get_db_image

      if img.nil? || @img_del == 'Y'
        no_image
      else
        set_image(img)
      end
    else
      set_image(@img)
    end

    btn_box = Gtk::Box.new(:horizontal)
    child.pack_start(btn_box, padding: 10)

    @image_btn = Gtk::Button.new(label: I18n.t('image.setting'))
    @image_btn.set_size_request(140, 50)
    btn_box.pack_start(@image_btn, expand: true)

    @delete_btn = Gtk::Button.new(label: I18n.t('menu.remove'))
    @delete_btn.set_size_request(140, 50)
    btn_box.pack_start(@delete_btn, expand: true)

    @close_btn = Gtk::Button.new(label: I18n.t('menu.close'))
    @close_btn.set_size_request(140, 50)
    btn_box.pack_start(@close_btn, expand: true)
  end

  def set_signal_connect
    @image_btn.signal_connect('clicked') do
      load_image_file
    end

    @delete_btn.signal_connect('clicked') do
      no_image

      @img_del = 'Y'
      @changed = true
    end

    @close_btn.signal_connect('clicked') do
      response(Gtk::ResponseType::OK) if @changed
      response(Gtk::ResponseType::CANCEL) unless @changed

      destroy
    end
  end

  def no_image
    @img = nil

    pixbuf = GdkPixbuf::Pixbuf.new(file: @no_image)

    set_image(pixbuf)
  end

  def set_image(pixbuf)
    return if pixbuf.nil?

    Dir.mkdir(@img_path) unless File.directory?(@img_path)

    new_width = 450
    new_height = 600

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

  def get_db_image

    file = @controller.get_image_info(@type, @id)

    if file.is_a?(String)
      dialog_message(@window, :error, :db_error, file)
      nil
    end

    if file.nil?
      nil
    else
      file_path = "#{@img_path}#{file.file_name}"
      GdkPixbuf::Pixbuf.new(file: file_path)
    end
  end

  def load_image_file
    file_dialog = Gtk::FileChooserDialog.new(:title => I18n.t('image.select'),
                                             :action => :open,
                                             :buttons => [[Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT],
                                                          [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]])

    file_dialog.set_default_size(150, 150)
    file_dialog.set_position(Gtk::WindowPosition::CENTER)
    file_dialog.resizable = false

    # ファイルのフィールター
    filter = Gtk::FileFilter.new
    filter.name = 'イメージファイル'
    filter.add_mime_type('image/jpeg')
    filter.add_mime_type('image/png')

    file_dialog.add_filter(filter)

    if file_dialog.run == Gtk::ResponseType::ACCEPT
      @img = GdkPixbuf::Pixbuf.new(file: file_dialog.filename)
      @file_name = file_dialog.filename
      @changed = true
    end

    file_dialog.destroy

    set_image(@img)

  end

end
