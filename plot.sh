#!/usr/bin/env ruby

# Make sure to install `ruby-graphviz` instead of `graphviz`
require 'graphviz'

OUTPUT = "./dependency-graph.png"
GREP_ROOT_DIR = "app/views/layouts"
GREP_EXCLUDE_DIRS = ['old', 'partials']

CMD_GCD="cd $(git rev-parse --show-toplevel)/#{GREP_ROOT_DIR}"
CMD_GREP="grep -Er 'stylesheet_link_tag|javascript_include_tag' . #{GREP_EXCLUDE_DIRS.map{ |dir| "--exclude-dir=#{dir}"}.join(' ')}"
CMD="#{CMD_GCD}; #{CMD_GREP}"

file_colors = {}

def random_color
  "#%06xff" % rand(2<<24 - 1)
end

g = GraphViz.new(:G,
                 :type => "digraph", # Strictness renders w/o duplicate edges
                 :rankdir => 'LR'   # Vertical graph
                )

matches = `#{CMD}`
matches.lines.each do |line|
  parts = line.match(/^([^:]*).+?((:\w+)|(\"[^\s]*\"))/)
  is_js = line.match("javascript")

  file = parts[1]
  file_colors[file] ||= random_color

  asset = "[#{is_js ? "JS" : "CSS"}] #{parts[2]}"

  g.add_nodes(file,
              shape: :box,
              style: :filled,
              fillcolor: file_colors[file]
             )

  g.add_nodes(asset,
              shape: (is_js ? "note" : "egg"),
              style: :filled,
              fillcolor: (is_js ? "red" : "yellow")
             )

  g.add_edge(file, asset,
              color: file_colors[file]
            )
end

g.output(:png => OUTPUT)

puts "Colors: Javascript => red, CSS => yellow"
puts "Matches found via:"
puts "\n    #{CMD}\n\n"
system("open #{OUTPUT}")
