# A StandardTerm is a standardized title for a musical work, ex. 
# Septet (from de Winter / VII Septuor)
#
# === Fields
# * <tt>title</tt> - the standardized title
# * <tt>title_d</tt> - downcase and stripped title
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Catalogue for a general description

class StandardTitle < ActiveRecord::Base

  has_and_belongs_to_many :sources
    
  validates_presence_of :title
    
  before_destroy :check_dependencies
    
  def check_dependencies
    return false if self.sources.count > 0
  end
   
end
