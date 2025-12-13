module ApplicationHelper
  # Sira color classes: info (blue), success (green), warn (orange), danger (red)

  CATEGORY_COLORS = {
    "Business" => "warn",
    "Science" => "info",
    "Health" => "success",
    "Sports" => "danger",
    "Arts and Entertainment" => "bw",
    "Technology" => "info",
    "Politics" => "danger",
    "Environment" => "success",
    "Education" => "info",
    "Crime" => "danger"
  }.freeze

  CONCEPT_TYPE_COLORS = {
    "person" => "info",
    "org" => "warn",
    "loc" => "success",
    "wiki" => "bw"
  }.freeze

  def category_color(category)
    return "bw" unless category
    CATEGORY_COLORS[category.short_name] || "bw"
  end

  def concept_type_color(concept_type)
    CONCEPT_TYPE_COLORS[concept_type] || "bw"
  end

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
end
