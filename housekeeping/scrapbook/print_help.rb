# Make a html version of collected help files

files= Dir[Rails.root.to_s+"/public/help/ch/*_de.html"]
ofile=File.open("#{Rails.root}/public/helpfiles.html", "w")

files.sort!.each do |f|
  ofile.write('<p   style="padding-top:2cm"    ><i>'+f+'</i></p>')
  ofile.write(File.open(f).read)
end

ofile.close

