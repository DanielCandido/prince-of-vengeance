import sys
from PIL import Image


def main() -> None:
    path, columns, rows = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    image = Image.open(path).convert("RGBA")
    cell_width = image.width / columns
    cell_height = image.height / rows
    print(f"{path}: {image.width}x{image.height}, cell={cell_width:.2f}x{cell_height:.2f}")
    for index in range(columns * rows):
        left = round((index % columns) * cell_width)
        top = round((index // columns) * cell_height)
        right = round(((index % columns) + 1) * cell_width)
        bottom = round(((index // columns) + 1) * cell_height)
        alpha = image.crop((left, top, right, bottom)).getchannel("A")
        bounds = alpha.getbbox()
        if bounds:
            print(f"  {index}: bounds={bounds}, visible={bounds[2] - bounds[0]}x{bounds[3] - bounds[1]}")
        else:
            print(f"  {index}: empty")


if __name__ == "__main__":
    main()
