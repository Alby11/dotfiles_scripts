import sys

import pylnk3


def read_lnk(path):
    # Create an Lnk object from the provided path
    lnk = pylnk3.Lnk(path)

    # Print the path the shortcut points to
    print(f"Path: {lnk.path}")  # Assuming 'path' might be the correct attribute

    # Print the working directory of the shortcut
    print(f"Working Directory: {lnk.working_dir}")

    # Print the arguments passed to the shortcut
    print(f"Arguments: {lnk.arguments}")
    # If 'path' is not correct, you might need to consult pylnk3's documentation or source code.
    # Common attributes might include lnk.real_path, lnk.working_dir, lnk.arguments, etc.


if __name__ == "__main__":
    # Check if the correct number of arguments is provided
    if len(sys.argv) != 2:
        print("Usage: python read_lnk.py path_to_shortcut.lnk")
        sys.exit(1)

    # Call the read_lnk function with the provided path
    read_lnk(sys.argv[1])
import pylnk3


def read_lnk(path):
    lnk = pylnk3.Lnk(path)
    print(f"Path: {lnk.path}")  # Assuming 'path' might be the correct attribute
    print(f"Working Directory: {lnk.working_dir}")
    print(f"Arguments: {lnk.arguments}")
    # If 'path' is not correct, you might need to consult pylnk3's documentation or source code.
    # Common attributes might include lnk.real_path, lnk.working_dir, lnk.arguments, etc.


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python read_lnk.py path_to_shortcut.lnk")
        sys.exit(1)

    read_lnk(sys.argv[1])
