import sys

def hex_from_file(file_path):
    try:
        with open(file_path, 'rb') as file:
            byte_count = 0x800
            byte = file.read(1)
            while byte:
                if byte_count % 8 == 0:
                    print( "  .byte ", end="" )
                    sep = ""
                print( sep, end="" )
                sep = ","
                print( "$"+byte.hex(), end='')
                # print( byte.hex(), end=" ")
                # x = int.from_bytes( byte, byteorder='big' )
                # if x>128:
                #     x -= 128
                # print( f"{x:02X} ", end=" " )
                byte_count += 1
                if byte_count % 8 == 0:
                    print()
                byte = file.read(1)
        print()
    except FileNotFoundError:
        print("File not found.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} file_path")
    else:
        hex_from_file( sys.argv[1] )
