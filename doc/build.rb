require 'rubygems'
require 'redcarpet'
require 'fileutils'

module MDbuild
  extend self

  def readme
    write_html("readme.html", html_content("readme.md"))
  end

  def docs
    Dir.glob(doc_files).each do |file_name|
      write_html(html_file_name(file_name), html_content(file_name))
    end
  end

  def reset_dir
    FileUtils.rm_r("doc/html")
    FileUtils.mkdir_p("doc/html")
  end

  def doc_files
    File.join(".","doc","*.md")
  end

  def html_file_name(file_name)
    file_name.match(/^.\/doc\/([a-z]*).md$/)[1] + ".html"
  end

  def html_content(file_name)
    contents = File.read(file_name)
    markdown = Redcarpet.new(contents, :fenced_code, :filter_html)
    markdown.to_html
  end

  def write_html(file_name, html_contents)
    File.open("./doc/html/#{file_name}", "w") {|f| f.write(html_contents) }
    puts file_name
  end

end

MDbuild.reset_dir
MDbuild.readme
MDbuild.docs
