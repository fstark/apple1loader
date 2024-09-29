# write a python program that takes a binary filename as an argument and produce a binary file composed of the bytes bettween 0x4a and 0xff (0xb6 bytes).
# The read the two 16 bits values at lomem ($4a) and himem ($4c)., stored littel endian.
# Append the content of the file between those two offsets to the output.

import sys

def read_little_endian_16(data, offset):
	return data[offset] + (data[offset + 1] << 8)

def main(input_filename, output_filename):
	with open(input_filename, 'rb') as f:
		data = f.read()

	# Extract zero page
	extracted_bytes = data[0x4a:0x100]

	# Read the 16-bit values at offsets 0x4A and 0x4C
	lomem = read_little_endian_16(data, 0x4A)
	himem = read_little_endian_16(data, 0x4C)

	# Extract content between lomem and himem
	content_between_offsets = data[lomem:himem]

	# Write the output to a new binary file
	with open(output_filename, 'wb') as f:
		f.write(extracted_bytes)
		f.write(content_between_offsets)

	print(f"LOMEM = ${lomem:04X}, HIMEM = ${himem:04X}")

if __name__ == "__main__":
	if len(sys.argv) != 3:
		print("Usage: python script.py <input_filename> <output_filename>")
		sys.exit(1)

	input_filename = sys.argv[1]
	output_filename = sys.argv[2]
	main(input_filename, output_filename)
