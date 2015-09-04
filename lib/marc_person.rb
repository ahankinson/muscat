class MarcPerson < Marc
  def initialize(source = nil)
    super("person", source)
  end

  def get_full_name_and_dates
    composer = ""
    composer_d = ""
    dates = nil

    if node = first_occurance("100", "a")
      if node.content
        composer = node.content.truncate(128)
        composer_d = node.content.downcase.truncate(128)
      end
    end

    if node = first_occurance("100", "d")
      if node.content
        dates = node.content.truncate(24)
      end
    end

    [composer, composer_d, dates]
  end

  def get_alternate_names_and_dates
    names = nil
    dates = nil

    if node = first_occurance("400", "a")
      if node.content
        names = node.content
      end
    end

    if node = first_occurance("400", "d")
      if node.content
        dates = node.content
      end
    end

    [names, dates]
  end

  def get_gender_birth_place_source_and_comments
    gender = 0
    birth_place = nil
    source = nil
    comments = nil

    if node = first_occurance("370", "a")
      if node.content
        birth_place = node.content.truncate(128)
      end
    end

    if node = first_occurance("375", "a")
      if node.content
        gender = 1
      end
    end

    if node = first_occurance("670", "a")
      if node.content
        source = node.content
      end
    end

    if node = first_occurance("680", "i")
      if node.content
        comments = node.content
      end
    end

    [gender, birth_place, source, comments]
  end


end
