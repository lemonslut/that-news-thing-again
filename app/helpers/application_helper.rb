module ApplicationHelper
  def category_color(category)
    return "info" unless category
    case category.short_name&.downcase
    when "politics" then "danger"
    when "business", "economy" then "success"
    when "technology", "science" then "info"
    when "sports" then "warn"
    when "entertainment" then "secondary"
    else "primary"
    end
  end

  def concept_type_color(concept_type)
    case concept_type
    when "person" then "secondary"
    when "org" then "info"
    when "loc" then "success"
    when "wiki" then "primary"
    else "bw"
    end
  end

  def trend_indicator(snapshot)
    return "" unless snapshot
    if snapshot.new_entry?
      '<span class="text-info font-medium">NEW</span>'.html_safe
    elsif snapshot.rising?
      change = snapshot.rank_change
      "<span class=\"text-success\">&#9650; #{change}</span>".html_safe
    elsif snapshot.falling?
      change = snapshot.rank_change.abs
      "<span class=\"text-danger\">&#9660; #{change}</span>".html_safe
    else
      '<span class="text-base-content/40">&#8212;</span>'.html_safe
    end
  end
end
