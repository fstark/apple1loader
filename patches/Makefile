OBJECTS=4KMEMTEST 8KMEMTEST NIM

all: $(OBJECTS)

clean:
	rm -f $(OBJECTS)

# All .asm files are built by running xa on them
%: %.asm
	xa -o $@ $<
