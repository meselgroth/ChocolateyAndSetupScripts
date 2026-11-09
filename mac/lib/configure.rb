#!/usr/bin/ruby
# Configuration edits used by setup and tested independently of macOS defaults.
require 'fileutils'
require 'rexml/document'

def write_changed(path, text)
  return if File.file?(path) && File.read(path) == text
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, text)
end

case ARGV.shift
when 'block'
  path, name, content = ARGV
  raise 'Missing block arguments' unless content
  first = "# >>> mac-setup #{name} >>>"
  last = "# <<< mac-setup #{name} <<<"
  original = File.exist?(path) ? File.read(path) : ''
  # Refuse malformed boundaries rather than silently deleting personal content.
  if original.scan(first).size != original.scan(last).size || original.scan(first).size > 1
    raise "Malformed managed block in #{path}"
  end
  block = "#{first}\n#{content}\n#{last}\n"
  pattern = /#{Regexp.escape(first)}\n.*?#{Regexp.escape(last)}\n?/m
  if original.include?(first)
    raise "Malformed managed block in #{path}" unless original.match?(pattern)
    result = original.sub(pattern) { block }
  else
    result = original + (original.empty? || original.end_with?("\n") ? '' : "\n") + block
  end
  write_changed(path, result)
when 'keymap'
  path = ARGV.fetch(0)
  document = REXML::Document.new(File.exist?(path) ? File.read(path) : '<application/>')
  root = document.root
  raise 'Expected application root' unless root && root.name == 'application'
  component = root.elements["component[@name='KeymapManager']"] || root.add_element('component', 'name' => 'KeymapManager')
  active = component.elements['active_keymap'] || component.add_element('active_keymap')
  active.attributes['name'] = 'Programming'
  output = ''
  REXML::Formatters::Default.new.write(document, output)
  write_changed(path, output + (output.end_with?("\n") ? '' : "\n"))
else
  abort 'Expected block or keymap'
end
