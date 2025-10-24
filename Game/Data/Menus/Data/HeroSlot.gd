extends Button

var hero_name
var avatar
var hero: UnitData

func setup(hero_ref: UnitData):
	hero_name = $Label
	avatar = $TextureRect

	hero = hero_ref

	hero_name.text = hero.name
	avatar.texture = hero.unit_model_data.get_avatar()
