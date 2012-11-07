require 'rubygems'
require 'fileutils'
require 'contest'
require 'test/unit'
require 'mocha'

require "#{File.expand_path(File.dirname(__FILE__))}/../lib/literati.rb"

TEST_CONTENT = "Hello there.

> Haskell code
> I have no clue what I'm doing.
> Syntax! :: Yeah! -> CURRYING.

More *Markdown*..."

TEST_CONTENT_WITH_COMMENT = "Well this is convenient.

>-- A comment, mi lord.
> WHAT?  WHERE???

Mo' content."

class DummyRenderer
  def initialize(content)
    @content = content
  end

  def to_html
    @content
  end
end

class LiteratiTest < Test::Unit::TestCase
  context "Markdown rendering" do
    setup do 
      @renderer = Literati::Renderer.new(TEST_CONTENT)
    end

    test "renders to Markdown string" do
      assert_match /\`\`\`haskell/m, @renderer.to_markdown
    end

    test "removes bird tracks" do
      assert_equal "more haskell codes", @renderer.remove_bird_tracks("> more haskell codes")
    end

    test "slurps remaining block properly" do
      assert_equal "\nline one\nline two\nline three", @renderer.slurp_remaining_bird_tracks(["> line one", "> line two", "> line three", ""])
    end
  end

  context "Markdown rendering with comments" do 
    setup do 
      @renderer = Literati::Renderer.new(TEST_CONTENT_WITH_COMMENT)
    end

    test "renders to Markdown string" do
      assert_match /\`\`\`haskell/m, @renderer.to_markdown
    end

    test "removes bird tracks" do
      assert_equal "-- a wild comment appears!", @renderer.remove_bird_tracks(">-- a wild comment appears!")
    end

    test "slurps remaining block properly" do
      assert_equal "\n-- line one\nline two\nline three", @renderer.slurp_remaining_bird_tracks([">-- line one", "> line two", "> line three", ""])
    end

    test "slurps remaining block properly with multiple comment lines" do
      assert_equal "\n-- line one\n--line two\nline three\n-- more commenting...", @renderer.slurp_remaining_bird_tracks([">-- line one", ">--line two", "> line three", ">-- more commenting...", ""])
    end
  end

  context "HTML rendering" do
    test "renders to HTML using our Smart Renderer(tm) by default" do
      Literati::MarkdownRenderer.any_instance.expects(:to_html)
      Literati.render("markdown\n\n> codes\n\nmoar markdown")
    end
    
    test "can use other Markdown class" do
      DummyRenderer.any_instance.expects(:to_html)

      renderer = Literati::Renderer.new("markdown\n\n> codes\n\nmoar markdown", DummyRenderer)
      renderer.to_html
    end
  end
end