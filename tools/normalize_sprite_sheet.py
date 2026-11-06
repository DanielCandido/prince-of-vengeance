import sys
from PIL import Image


def main() -> None:
    source, destination = sys.argv[1:3]
    columns, rows = int(sys.argv[3]), int(sys.argv[4])
    targets = [int(value) for value in sys.argv[5].split(",")]
    image = Image.open(source).convert("RGBA")
    source_width = image.width / columns
    source_height = image.height / rows
    output = Image.new("RGBA", (columns * 512, rows * 512))
    for index in range(columns * rows):
        left = round((index % columns) * source_width)
        top = round((index // columns) * source_height)
        right = round(((index % columns) + 1) * source_width)
        bottom = round(((index // columns) + 1) * source_height)
        frame = image.crop((left, top, right, bottom))
        bounds = frame.getchannel("A").getbbox()
        if not bounds:
            continue
        content = frame.crop(bounds)
        target_height = targets[min(index // 2, len(targets) - 1)]
        scale = min(target_height / content.height, 480 / content.width)
        size = (max(1, round(content.width * scale)), max(1, round(content.height * scale)))
        content = content.resize(size, Image.Resampling.LANCZOS)
        x = (index % columns) * 512 + (512 - size[0]) // 2
        y = (index // columns) * 512 + 480 - size[1]
        output.alpha_composite(content, (x, y))
    output.save(destination)


if __name__ == "__main__":
    main()
