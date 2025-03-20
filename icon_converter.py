#!/usr/bin/env python3
from PIL import Image
from os import path, walk
import argparse
import sys
import re

def validate_rgba(rgba_string):
    """Validate RGBA string format and values."""
    # Match format like "255,255,255,255" or "255, 255, 255, 255"
    pattern = re.compile(r'^\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*$')
    match = pattern.match(rgba_string)
    
    if not match:
        return None
    
    # Convert to integers and validate range (0-255)
    try:
        rgba = tuple(int(v) for v in match.groups())
        if all(0 <= v <= 255 for v in rgba):
            return rgba
        return None
    except ValueError:
        return None

def create_dark_icon(icon_path, color):
    """Convert an icon to dark mode by changing its color to the specified RGBA value."""
    try:
        pil_image = Image.open(icon_path).convert("RGBA")
        img_data = pil_image.getdata()
        new_img_data = []
        
        for px in img_data:
            if px[3] > 0:  # If pixel has opacity
                new_img_data.append((color[0], color[1], color[2], px[3]))
            else:
                new_img_data.append(px)
                
        pil_image.putdata(new_img_data)
        new_icon_path = icon_path.replace(".png", ".dark.png")
        pil_image.save(new_icon_path)
        return new_icon_path
    except Exception as e:
        print(f"Error processing {icon_path}: {e}")
        return None

def get_all_icons(dir_path):
    """Find all files ending with 'icon.png' in the given directory and subdirectories."""
    for root, dirs, files in walk(dir_path):
        for file in files:
            if file.endswith("icon.png"):
                yield path.join(root, file)

def process_directory(dir_path, color):
    """Process all icons in the given directory using the specified color."""
    count = 0
    converted = 0
    
    print(f"\nSearching for icons in: {dir_path}")
    print(f"Using color: RGB({color[0]}, {color[1]}, {color[2]}) with Alpha {color[3]}")
    
    for icon_file in get_all_icons(dir_path):
        count += 1
        print(f"Processing: {icon_file}")
        new_path = create_dark_icon(icon_file, color)
        if new_path:
            converted += 1
            print(f"Created dark version: {new_path}")
    
    print("\nConversion complete!")
    print(f"Found {count} icons, successfully converted {converted} to dark mode")
    
    return count, converted

def main():
    """Main function to run the terminal application."""
    print("=" * 60)
    print("ICON DARK MODE CONVERTER".center(60))
    print("This tool converts PNG icons to dark mode by changing their color".center(60))
    print("=" * 60)
    
    # Set up argument parser for command-line options
    parser = argparse.ArgumentParser(description='Convert icons to dark mode')
    parser.add_argument('-d', '--directory', help='Directory to process')
    parser.add_argument('-c', '--color', help='RGBA color value (e.g., "240,240,240,255")')
    args = parser.parse_args()
    
    # Default color (light gray)
    color = (240, 240, 240, 255)
    
    # If color was provided as an argument, use it
    if args.color:
        validated_color = validate_rgba(args.color)
        if validated_color:
            color = validated_color
        else:
            print("Invalid color format. Expected: R,G,B,A (e.g., 240,240,240,255)")
            print(f"Using default color: {color}")
    else:
        # Ask user if they want to use a custom color
        use_custom = input("Do you want to use a custom color? (y/n, default: n): ").strip().lower()
        if use_custom == 'y' or use_custom == 'yes':
            color_input = input("Enter RGBA color values (e.g., 240,240,240,255): ").strip()
            validated_color = validate_rgba(color_input)
            if validated_color:
                color = validated_color
                print(f"Using custom color: {color}")
            else:
                print("Invalid color format. Using default light gray.")
    
    # If directory was provided as an argument, use it
    if args.directory:
        dir_path = args.directory
    else:
        # Otherwise, ask the user for input
        dir_path = input("Enter the directory path to process: ").strip()
    
    # Check if the path exists
    if not path.isdir(dir_path):
        print(f"Error: The path '{dir_path}' is not a valid directory.")
        return
    
    # Process the directory
    process_directory(dir_path, color)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        print(f"\nAn unexpected error occurred: {e}")
        sys.exit(1)