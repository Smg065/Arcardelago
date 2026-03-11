extends GraphNode
class_name GraphNodeImage

var curImage : Image

func file_selected(path: String) -> void:
	var newImage := Image.load_from_file(path)
	if newImage == null:
		return
	curImage = newImage
	$VBoxContainer/CheckerBackdrop/ImageDisplay	.texture = ImageTexture.create_from_image(newImage)
