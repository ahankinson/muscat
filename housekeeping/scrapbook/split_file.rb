# Split HUGE xml files into chunks
# first argument is the file containing marc records
# second is the model name
# third is the offset to start from

SIZE=50000
#
def change_subfield_code(node, tag, old_code, new_code)
      subfield=node.xpath("//datafield[@tag='#{tag}']/subfield[@code='#{old_code}']")
      subfield.attr('code', new_code) if subfield
      subfield
end

def change_datafield(node, tag, new_tag)
      datafield=node.xpath("//datafield[@tag='#{tag}']")
      datafield.attr('tag', new_tag) if datafield
      datafield
end

def change_collection(node)
      subfield=node.xpath("//datafield[@tag='100']/subfield[@code='a']")
      if subfield.text=='Collection'
        node.xpath("//datafield[@tag='100']").remove
        change_datafield(node, '240', '130')
      end
end



if ARGV.length >= 2
  source_file = ARGV[0]
  model = ARGV[1]
  start = 0
  ofile=File.open("#{Rails.root}/public/#{"%06d" % start}.xml", "w")
  ofile.write("<collection>")
  if File.exists?(source_file)
    import = MarcImport.new(source_file, model, start.to_i)
    import.each_record(source_file) { |record|
      change_collection(record)
      change_datafield(record, '762', '772')
      change_datafield(record, '504', '690')
      change_datafield(record, '510', '691')
      change_subfield_code(record,'773', 'a', 'w')

      #Sorting tags
      nodes = record.xpath("//datafield").remove
      nodes.sort_by{|node| node.attr("tag")}.each{|node| record.add_child(node)}
      doc = Nokogiri::XML.parse(record.to_s) do |config|
        config.noblanks
      end

      ofile.write(doc.root.to_xml :encoding => 'UTF-8')
      start+=1
      if start % SIZE == 0
        ofile.write("</collection>")
        puts start
        ofile.close
        ofile=File.open("#{Rails.root}/public/#{"%06d" % start}.xml", "w")
        ofile.write("<collection>")
      end
      #break if start==100
    }



    puts "\nCompleted: "+Time.new.strftime("%Y-%m-%d %H:%M:%S")
  else
    puts source_file + " is not a file!"
  end
else
  puts "Bad arguments, specify marc file and model class to use"
end
