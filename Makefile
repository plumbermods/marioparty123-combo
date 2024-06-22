PRINT := printf '
 ENDCOLOR := \033[0m
 WHITE     := \033[0m
 ENDWHITE  := $(ENDCOLOR)
 GREEN     := \033[0;32m
 ENDGREEN  := $(ENDCOLOR)
 BLUE      := \033[0;34m
 ENDBLUE   := $(ENDCOLOR)
 YELLOW    := \033[0;33m
 ENDYELLOW := $(ENDCOLOR)
 PURPLE    := \033[0;35m
 ENDPURPLE := $(ENDCOLOR)
ENDLINE := \n'


# List of source files
C_SOURCES = $(wildcard src/*.c)

# List of .s files
ASM_SOURCES = $(wildcard asm/*.s)

# List of object files, generated from the source files
OBJECTS = $(C_SOURCES:src/%.c=obj/%.o)

OUTPUT_FILE = asm/main.asm

INCLUDE_FLAGS = -Iinclude -Iinclude/PR

CC := mips64-elf-gcc
STANDARDFLAGS := -O2 -Wall -Wno-missing-braces -mtune=vr4300 -march=vr4300 -mabi=32 -fomit-frame-pointer -mno-abicalls -fno-pic -G0
SPEEDFLAGS := -Os -Wall -Wno-missing-braces -mtune=vr4300 -march=vr4300 -mabi=32 -fomit-frame-pointer -mno-abicalls -fno-pic -G0

# Default target
all: $(OBJECTS) genMain assemble

# Rule for building object files from source files
obj/%.o: src/%.c | obj
	@$(PRINT)$(GREEN)Compiling C file: $(ENDGREEN)$(BLUE)$<$(ENDBLUE)$(ENDCOLOR)$(ENDLINE)
	@$(CC) $(STANDARDFLAGS) $(INCLUDE_FLAGS) -c $< -o $@

assemble: $(OBJECTS)
	@$(PRINT)$(GREEN)Assembling with armips: $(ENDGREEN)$(BLUE)asm/main.asm$(ENDBLUE)$(ENDCOLOR)$(ENDLINE)
	@armips asm/main.asm -sym syms.txt
	@$(PRINT)$(GREEN)n64crc $(ENDGREEN)$(BLUE)"rom/mp3-mp2.mod.z64"$(ENDBLUE)$(ENDCOLOR)$(ENDLINE)
	@./n64crc.exe "rom/mp3-mp2.mod.z64"

#.asm files are explicity set in the build system, .s files automatically appended
genMain:
	@$(PRINT)$(GREEN)Generating: $(ENDGREEN)$(BLUE)asm/main.asm$(ENDBLUE)$(ENDCOLOR)$(ENDLINE)
	$(file > $(OUTPUT_FILE),//Automatically generated by makefile, do not edit)
	$(file >> $(OUTPUT_FILE),.n64 // Let armips know we're coding for the N64 architecture)
	$(file >> $(OUTPUT_FILE),.open "rom/mp3-mp2.z64", "rom/mp3-mp2.mod.z64", 0 // Open the ROM file)
	$(file >> $(OUTPUT_FILE),.include "asm/mp2_symbols.asm")
	$(file >> $(OUTPUT_FILE),.include "asm/mp3_symbols.asm")
	$(file >> $(OUTPUT_FILE),.include "asm/patchBoot.asm")
# we use the extra ROM space of mp1 to store all of our custom code
	$(file >> $(OUTPUT_FILE),.headersize 0x7E502580)
	$(file >> $(OUTPUT_FILE),.org 0x80400000)
	$(file >> $(OUTPUT_FILE),PAYLOAD_START_RAM:)
	$(foreach s_file,$(ASM_SOURCES),$(file >> $(OUTPUT_FILE),.include "$(s_file)"))
	$(foreach obj_file,$(OBJECTS),$(file >> $(OUTPUT_FILE),.importobj "$(obj_file)"))
	$(file >> $(OUTPUT_FILE), .align 8)
	$(file >> $(OUTPUT_FILE), PAYLOAD_END_RAM:)
	$(file >> $(OUTPUT_FILE),.close //close file)

# Rule for creating the obj folder
obj:
	@mkdir -p obj

# Rule for cleaning up the project
clean:
	@rm -f $(OBJECTS)