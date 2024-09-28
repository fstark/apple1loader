## Patches

Some software needs to be patched after being loaded in memory but before being executed

Patches are loaded just *before* the load address, and execution starts at the patch.

The are two main reasons for this:

Some software does not start at the beginning, and the loader has currently no provision for a start address different from the load addres. An example if NIM, which is loaded at $280 but is started with a 4AFR.

Some software needs some configuration before being started. For instance, the memory test reads address 00 through 03 to know which range of memory to test. By having two copies with different patches, we get a 4K and 8K memory test.
