from collections import deque
import sys

from PIL import Image


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return min(red, green, blue) >= 225 and max(red, green, blue) - min(red, green, blue) <= 18


def main() -> None:
    source, destination = sys.argv[1:3]
    gradient_mode = len(sys.argv) > 3 and sys.argv[3] == "gradient"
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    visited = bytearray(width * height)

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        index = y * width + x
        if visited[index] or (not gradient_mode and not is_background(pixels[x, y])):
            continue
        visited[index] = 1
        red, green, blue, _alpha = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        for neighbor_x, neighbor_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= neighbor_x < width and 0 <= neighbor_y < height):
                continue
            if gradient_mode:
                neighbor = pixels[neighbor_x, neighbor_y]
                if max(abs(red - neighbor[0]), abs(green - neighbor[1]), abs(blue - neighbor[2])) > 7:
                    continue
            queue.append((neighbor_x, neighbor_y))

    image.save(destination)


if __name__ == "__main__":
    main()
