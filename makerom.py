import sys
import json

def load_json_file(filename):
    try:
        with open(filename, 'r') as file:
            data = json.load(file)
        return data
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
    except json.JSONDecodeError:
        print(f"Error: '{filename}' is not a valid JSON file.")

def parse_hex_string(hex_string):
    parsed_values = []
    
    for char in hex_string:
        try:
            # Attempt to convert the hexadecimal character to its decimal value
            decimal_value = int(char, 16)
            parsed_values.append(decimal_value)
        except ValueError:
            # Handle non-hexadecimal characters
            print(f"Error: '{char}' is not a valid hexadecimal character.")
    
    return parsed_values

def find_identical_modulo_eight(numbers):
    seen_modulo = {}

    for num in numbers:
        modulo_eight = num % 8

        if modulo_eight in seen_modulo:
            return [seen_modulo[modulo_eight], num]

        seen_modulo[modulo_eight] = num

    return None

def to_hex( num ):
    return "0123456789ABCDEF"[num]

def load_binary_file(filename):
    try:
        with open(filename, 'rb') as file:
            binary_data = file.read()
        
        # Convert the binary data to an array of integers
        integer_array = [int(byte) for byte in binary_data]
        
        # Ensure that the integers are within the range [0, 255]
        # Check that all integers are within the range [0, 255]
        for value in integer_array:
            if not (0 <= value <= 255):
                raise ValueError(f"Value {value} is outside the valid range [0, 255]")

        return integer_array
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")

def parse_hex_number(hex_string):
    if not (hex_string.startswith("0x") and len(hex_string) == 6 and all(c in "0123456789ABCDEF" for c in hex_string[2:])):
        raise ValueError("Invalid hex string format or content")

    try:
        hex_value = int(hex_string, 16)
        return hex_value
    except ValueError:
        raise ValueError("Invalid hex value")

menu = []

def add_menu_exec( key, name, adrs ):
    menu.append( 1 )
    menu.append( adrs%256 )
    menu.append( int(adrs/256) )
    menu.append( 0 )
    menu.append( 0 )
    menu.append( 0 )
    menu.append( 0 )
    menu.append( ord(key) )
    menu.append( [ord(c) for c in name] )
    menu.append( 0x0d )

def add_menu_copy( key, name, adrs, len, to ):
    menu.append( 2 )
    menu.append( adrs%256 )
    menu.append( int(adrs/256) )
    menu.append( len%256 )
    menu.append( int(len/256) )
    menu.append( to%256 )
    menu.append( int(to/256) )
    menu.append( ord(key) )
    menu.append( [ord(c) for c in name] )
    menu.append( 0x0d )

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python makerom.py <json_file>")
        sys.exit( 1 )

    json_filename = sys.argv[1]
    loaded_data = load_json_file(json_filename)
    if loaded_data is None:
        sys.exit( 2 )

    map = sorted(parse_hex_string(loaded_data["map"]))
    if map==None:
        print( "There should be a top-level 'map' key" )
        sys.exit( 3 )

    dups = find_identical_modulo_eight(parse_hex_string(loaded_data["map"]))
    if dups is not None:
        print( f"Error duplicate banks {to_hex(dups[0])} and {to_hex(dups[1])} in map" )
        sys.exit( 4 )

    rom = [0] * 32768       # Rom data
    usage = [-2] * 32768    # Which content went here (-2 == free, -1 == menu, 0-n == content)

    mem2rom = [-1] * 65536
    rom2mem = [-1] * 32768

        # We fill to arrays to convert addresses
    for i in map:
        membase = 4096*i            # base address for that block in rom
        rombase = membase % 32768   # address in rom
        for j in range(4096):
            mem2rom[membase+j] = rombase+j
            rom2mem[rombase+j] = membase+j

        # copy to rom
    failed = False
    next_adrs = map[0]*4096 # First available address
    content_index = 0
    for content in loaded_data["content"]:
        data = load_binary_file( content["path"] )
        adrs = next_adrs    # Default
        if "adrs" in content:
            adrs = parse_hex_number( content["adrs"] )
        content["real_adrs"] = adrs
        content["real_len"] = len(data)
        type = content["type"]
        for i in range(len(data)):
            mem_adrs = adrs+i
            next_adrs = mem_adrs+1
            rom_adrs = mem2rom[mem_adrs]
            if rom_adrs==-1:
                print( f"**** Memory at 0x{mem_adrs:04X} is not mapped when copying {content['path']} (offset {i}/{len(data)})")
                failed = True
                break
            if usage[rom_adrs]!=-2:
                print( f"**** Memory clash at address 0x{mem_adrs:04X}" )
                print( f"   File {content['path']} clases with file {loaded_data['content'][usage[rom_adrs]]['path']}" )
                failed = True
                break
            rom[rom_adrs] = data[i]
            usage[rom_adrs] = content_index
        # Menu entry
        # if type=="exec":
        #     menu[content_index]

        content_index += 1
        if failed:
            break

    # Generate menu
    for key in loaded_data["loader"]["keys"]:
        for content in loaded_data["content"]:
            if "key" in content and content["key"]==key:
                if content["type"]=="exec":
                    add_menu_exec( key, content["menu"], content["real_adrs"] )
                if content["type"]=="copy":
                    exec_adrs = 0x280
                    add_menu_copy( key, content["menu"], content["real_adrs"], content["real_len"], exec_adrs )

    # Insert menu (code dup)
    menu_adrs = parse_hex_number(loaded_data["loader"]["menu_adrs"])
    for i in range(len(menu)):
        mem_adrs = menu_adrs+i
        next_adrs = mem_adrs+1
        rom_adrs = mem2rom[mem_adrs]
        if rom_adrs==-1:
            print( f"**** Memory at 0x{mem_adrs:04X} is not mapped when copying menu (offset {i}/{len(data)})")
            failed = True
            break
        if usage[rom_adrs]!=-2:
            print( f"**** Memory clash at address 0x{mem_adrs:04X}" )
            print( f"   Menu clashes with file {loaded_data['content'][usage[rom_adrs]]['path']}" )
            failed = True
            break
        rom[rom_adrs] = menu[i]
        usage[rom_adrs] = -1

        # Print stats
    print( "Software map:" )
    content_index = 0
    for content in loaded_data["content"]:
        print( f"{content['path']} :\n", end="" )
        found = False
        for i in range(32768):
            if not found and usage[i]==content_index:
                print( f"        0x{i:04X}/0x{rom2mem[i]:04X}-", end="")
                found = True
            else:
                if found and usage[i]!=content_index:
                    print( f"0x{i-1:04X}/0x{rom2mem[i-1]:04X} ", end="")
                    found = False
        if found:
            print( f"0x{32767:04X}/0x{rom2mem[32767]:04X} ", end="")
        print( "" )
        content_index += 1

    print( "\n\nROM map:" )
    current_content = -1 # Free
    for i  in range(32768):
        new_content = usage[i]
        if new_content!=current_content:
            print( f"0x{i:04X} : ", end="" )
            if new_content>=0:
                print( f"{loaded_data['content'][new_content]['path']}")
            else:
                if new_content==-1:
                    print( "MENU")
                if new_content==-2:
                    print( "FREE")
            current_content = new_content

    print( "\n\nMEM map:" )
    current_content = -1 # Free
    for i  in range(65536):
        if mem2rom[i]==-1:
            new_content = -3
        else:
            new_content = usage[mem2rom[i]]
        if new_content!=current_content:
            print( f"0x{i:04X} : ", end="" )
            if new_content>=0:
                print( f"{loaded_data['content'][new_content]['path']}")
            else:
                if new_content==-1:
                    print( "MENU")
                if new_content==-2:
                    print( "FREE")
                if new_content==-3:
                    print( "NOT MAPPED")
            current_content = new_content
