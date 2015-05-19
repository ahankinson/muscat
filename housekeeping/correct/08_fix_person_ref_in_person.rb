Person.all.each do |s|
  count=0
  marc = s.marc
  modified = false
  #puts "OLD MARC ############################## OLD MARC"
  #puts marc 
  marc.each_by_tag("509") do |t|
  counter=0
    a = t.fetch_first_by_tag("0")
    if a 
      if a.content
        reference=a.content
        person=Person.find(reference)
        if person
          t.add(MarcNode.new(Person, "a", person.name, nil)) if !t.fetch_first_by_tag("a")
        end
        modified = true
        puts s.id
      end
    end
  
  

  end
  #puts "NEW MARC ========================================"
  #puts marc if modified
  s.marc=marc
  s.save if modified

end
