# frozen_string_literal: true

class Page
  attr_reader  :total_count, :per_page,
               :current_block, :total_block, :total_pages
  attr_accessor :current_page

  def initialize(count, current_page)
    @total_count = count
    @current_page = current_page
    @per_page = 100
    @per_block = 5
    @current_block = (@current_page / @per_block.to_f).ceil
    @total_block = (total_pages / @per_block) + 1
  end

  def total_pages
    (@total_count / @per_page.to_f).ceil
  end

  def page_numbers

    start_block = @current_block + ((@current_block - 1) * (@per_block - 1))

    return if start_block > total_pages

    (start_block..total_pages).to_a.take(@per_block)

  end

  def next_page
    @current_block += 1 if @current_block < (total_pages / @per_block.to_f).ceil
  end

  def previous_page
    @current_block -= 1 if @current_block > 1
  end

  def first_page
    @current_block = 1
  end

  def last_page
    @current_block = (total_pages / @per_block.to_f).ceil
  end

  def offset
    (@current_page - 1) * @per_page
  end

  def limit
    @per_page
  end
end
