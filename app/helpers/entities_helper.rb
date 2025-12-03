module EntitiesHelper
  def entity_link(entity)
    link_to entity.name, entity_path(entity), class: "entity-link"
  end

  def entity_link_by_type_and_name(type, name)
    entity = Entity.find_by(entity_type: type, name: name)
    if entity
      link_to name, entity_path(entity), class: "entity-link"
    else
      name
    end
  end
end
