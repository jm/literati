Literati
========

Render literate Haskell into HTML using Ruby and magic.  But mostly Ruby.

    Literati.render("Markdown here\n\n> your literate Haskell here\n\nMore Markdown.")
    # =>  <p>Markdown here</p>

          <pre><code class="haskell">your literate Haskell here
          </code></pre>

          <p>More Markdown.</p>

Simple and straightforward!  

By default, we render using Markdown.  If you want to use another markup language or Markdown renderer, then you can use the extra magical extended API.  The only requirement is that the class takes the content as the sole argument for the initializer and exposes a `to_html` method.  An example `RedCarpet` wrapper would look like this:

    # A simple class to wrap passing the right arguments to RedCarpet.
    class RedCarpetRenderer
      # Create a new compatibility instance.
      #
      # content - The Markdown content to render.
      def initialize(content)
        require 'redcarpet/compat'
        @content = content
      end

      # Render the Markdown content to HTML.  We use GFM-esque options here.
      #
      # Returns an HTML string.
      def to_html
        Markdown.new(@content, :fenced_code, :safelink, :autolink).to_html
      end
    end

You can easily use that as a base for other wrappers.  If you wanted to use, for example, a `reStructuredText` wrapper of some sort with `literati`, you'd do something like this:

    renderer = Literati::Renderer.new("content", RSTRenderer)
    renderer.to_html

The second, optional argument to the `Renderer` class's initializer is the class (i.e., *not* an instance) that you'll use to build the HTML.  If you leave that option off, it'll default to our `RedCarpetRenderer` class.

Lastly, you can use the simple binscript we included:

    literati file.lhs

That'll pipe the HTML to `stdout` so you can direct it wherever.
