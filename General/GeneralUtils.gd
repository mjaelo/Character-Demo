extends Node

# Array utilities
func has_all(main_array: Array, elements_array: Array) -> bool:
	for element in elements_array:
		if element not in main_array:
			return false
	return true

func has_any(main_array: Array, elements_array: Array) -> bool:
	for element in elements_array:
		if element in main_array:
			return true
	return false

