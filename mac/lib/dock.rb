#!/usr/bin/ruby
require 'rexml/document'
require 'open3'
require 'fileutils'
require 'uri'

module DockCleanup
  APP_IDS = %w[com.apple.iCal com.apple.mail com.apple.AddressBook com.apple.Maps
               com.apple.MobileSMS com.apple.iChat com.apple.Music com.apple.news
               com.apple.siri.launcher com.apple.Siri com.apple.reminders].freeze
  APP_NAMES = %w[Calendar Mail Contacts Maps Messages Music News Siri Reminders].freeze

  def self.value(dict, key)
    return nil unless dict && dict.name == 'dict'
    elements = dict.elements.to_a
    index = elements.index { |element| element.name == 'key' && element.text == key }
    index ? elements[index + 1] : nil
  end

  def self.remove?(tile)
    data = value(tile, 'tile-data')
    identifier = value(data, 'bundle-identifier')&.text
    return APP_IDS.include?(identifier) if identifier && !identifier.empty?
    # Older tiles may have no bundle ID. Match Apple app paths, never labels.
    url = value(value(data, 'file-data'), '_CFURLString')&.text
    return false unless url
    path = URI::DEFAULT_PARSER.unescape(url).sub(%r{/$}, '')
    APP_NAMES.any? { |name| ["file:///System/Applications/#{name}.app", "file:///Applications/#{name}.app"].include?(path) }
  end

  def self.changes(xml)
    document = REXML::Document.new(xml)
    root = document.elements['plist/dict']
    raise 'Expected a Dock preference dictionary' unless root
    result = {}
    %w[persistent-apps recent-apps].each do |key|
      array = value(root, key)
      next unless array
      raise "Expected an array for #{key}" unless array.name == 'array'
      tiles = array.elements.to_a
      kept = tiles.reject { |tile| remove?(tile) }
      result[key] = kept.map(&:to_s) if kept.size != tiles.size
    end
    result
  end

  def self.apply(backup_dir)
    xml, status = Open3.capture2('defaults', 'export', 'com.apple.dock', '-')
    raise 'Could not read Dock preferences; run from your logged-in Mac account.' unless status.success?
    updates = changes(xml)
    if updates.empty?
      puts 'Requested Apple apps are already absent from pinned and recent Dock entries.'
      return
    end
    saved = File.join(backup_dir, 'defaults/com.apple.dock.plist')
    unless File.exist?(saved) || File.exist?(saved + '.absent')
      FileUtils.mkdir_p(File.dirname(saved))
      File.write(saved, xml, mode: 'w', perm: 0600)
    end
    updates.each do |key, tiles|
      # Change only the affected array; preserve all other Dock settings.
      raise "Could not update Dock #{key}" unless system('defaults', 'write', 'com.apple.dock', key, '-array', *tiles)
    end
    raise 'Dock cleanup verification failed' unless changes(Open3.capture2('defaults', 'export', 'com.apple.dock', '-').first).empty?
    system('killall', 'Dock')
    puts "Removed requested Apple Dock entries. Backup: #{saved}"
  end
end

DockCleanup.apply(ARGV.fetch(0)) if $PROGRAM_NAME == __FILE__
