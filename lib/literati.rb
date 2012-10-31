require 'rubygems'

module Literati
  VERSION = '0.0.2'

  # Render the given content to HTML.
  #
  # content - Literate Haskell content to render to HTML
  #
  # Returns the literate Haskell rendered as HTML.
  def self.render(content)
    Renderer.new(content).to_html
  end

  # A simple class to wrap passing the right arguments to RedCarpet.
  class MarkdownRenderer
    class GitHubWrapper
      def initialize(content)
        @content = content
      end

      def to_html
        GitHub::Markdown.render(@content)
      end
    end

    # Create a new compatibility instance.
    #
    # content - The Markdown content to render.
    def initialize(content)
      @content = content
    end

    def determine_markdown_renderer
      @markdown = if installed?('github/markdown')
        GitHubWrapper.new(@content)
      elsif installed?('redcarpet/compat')
        Markdown.new(@content, :fenced_code, :safelink, :autolink)
      elsif installed?('redcarpet')
        RedcarpetCompat.new(@content)
      elsif installed?('rdiscount')
        RDiscount.new(@content)
      elsif installed?('maruku')
        Maruku.new(@content)
      elsif installed?('kramdown')
        Kramdown::Document.new(@content)
      elsif installed?('bluecloth')
        BlueCloth.new(@content)
      end
    end

    def installed?(file)
      begin
        require file
        true
      rescue LoadError
        false
      end
    end

    # Render the Markdown content to HTML.  We use GFM-esque options here.
    #
    # Returns an HTML string.
    def to_html
      determine_markdown_renderer
      @markdown.to_html
    end
  end

  class Renderer
    # The Markdown class we're using to render HTML; is our
    # RedCarpet wrapped by default.
    attr_accessor :markdown_class

    # Regex used to determine presence of Bird-style comments
    BIRD_TRACKS_REGEX = /^\> (.*)/

    # Initialize a new literate Haskell renderer.
    #
    # content - The literate Haskell code string
    # markdowner - The class we'll use to render the HTML (defaults
    #              to our RedCarpet wrapper).
    def initialize(content, markdowner = MarkdownRenderer)
      @bare_content = content
      @markdown = to_markdown
      @markdown_class = markdowner
    end

    # Render the given literate Haskell to a Markdown string.
    #
    # Returns a Markdown string we can render to HTML.
    def to_markdown
      lines = @bare_content.split("\n")
      markdown = ""

      # Using `while` here so we can alter the collection at will
      while current_line = lines.shift
        # If we got us some of them bird tracks...
        if current_line =~ BIRD_TRACKS_REGEX
          # Remove the bird tracks from this line
          current_line = remove_bird_tracks(current_line)
          # Grab the remaining code block
          current_line << slurp_remaining_bird_tracks(lines)

          # Fence it and add it to the output
          markdown << "```haskell\n#{current_line}\n```\n"
        else
          # No tracks?  Just stick it back in the pile.
          markdown << current_line + "\n"
        end
      end

      markdown
    end

    # Remove Bird-style comment markers from a line of text.
    #
    #   comment = "> Haskell codes"
    #   remove_bird_tracks(comment)
    #   # => "Haskell codes"
    #
    # Returns the given line of text sans bird tracks.
    def remove_bird_tracks(line)
      line.gsub(BIRD_TRACKS_REGEX, '\1')
    end

    # Given an Array of lines, pulls from the front of the Array
    # until the next line doesn't match our bird tracks regex.
    #
    #   lines = ["> code", "> code", "", "not code"]
    #   slurp_remaining_bird_tracks(lines)
    #   # => "code\ncode"
    #
    # Returns the lines mashed into a string separated by a newline.
    def slurp_remaining_bird_tracks(lines)
      tracked_lines = []

      while lines.first =~ BIRD_TRACKS_REGEX
        tracked_lines << remove_bird_tracks(lines.shift)
      end

      if tracked_lines.empty?
        ""
      else
        "\n" + tracked_lines.join("\n")
      end
    end

    # Render the Markdown string into HTML using the previously
    # specified Markdown renderer class.
    #
    # Returns an HTML string.
    def to_html
      @markdown_class.new(@markdown).to_html
    end
  end
end