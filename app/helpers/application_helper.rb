module ApplicationHelper
  def sentiment_color(sentiment)
    return "" unless sentiment
    if sentiment > 0.2
      "text-success"
    elsif sentiment < -0.2
      "text-danger"
    else
      "text-warn"
    end
  end

  def sentiment_indicator(sentiment)
    return nil unless sentiment
    if sentiment > 0.2
      "+"
    elsif sentiment < -0.2
      "-"
    else
      "~"
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
