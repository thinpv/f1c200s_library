TARGET = f1c200s_library
OPT = -Ofast
BUILD_DIR = output
CPU = -mcpu=arm926ej-s
FPU =
FLOAT-ABI = -mfloat-abi=soft
LDSCRIPT = user/link.lds
AS_DEFS = 
C_DEFS =  \
-D__ARM32_ARCH__=5 \
-D__ARM926EJS__ \
-D_POSIX_C_SOURCE

PREFIX = /opt/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
AR = $(PREFIX)ar rcs
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
BIN = $(CP) -O binary -S
ifdef OS
   RM = rmdir /Q /S
else
   ifeq ($(shell uname), Linux)
      RM = rm -r
   endif
endif

######################################
# source
######################################
# C sources
SDK_DIR = \
	bootloader \
	f1cx00s_lib/src \
	third_party/rt-thread/bsp \
	third_party/rt-thread/components/libc/compilers/common \
	third_party/rt-thread/components/libc/compilers/newlib \
	third_party/rt-thread/libcpu/f1c100s \
	third_party/rt-thread/src

C_DIR = \
	dsp/source/**/src \
	hardware/src \
	system/src \
	user

# ASM sources
S_DIR = \
	bootloader \
	third_party/rt-thread/libcpu/f1c100s

# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES = \
-Ibootloader \
-Idsp/include \
-If1cx00s_lib/inc \
-Ihardware/inc \
-Imyresource/inc \
-Isystem/inc \
-Ithird_party/cherryusb \
-Ithird_party/cherryusb/class/hub \
-Ithird_party/cherryusb/class/msc \
-Ithird_party/cherryusb/common \
-Ithird_party/cherryusb/core \
-Ithird_party/cherryusb/osal \
-Ithird_party/cherryusb/port \
-Ithird_party/fatfs \
-Ithird_party/lvgl \
-Ithird_party/lvgl/lvgl/demos \
-Ithird_party/lvgl/lvgl/porting \
-Ithird_party/rt-thread/include \
-Ithird_party/rt-thread/bsp \
-Ithird_party/rt-thread/components/libc/compilers/common/include \
-Ithird_party/rt-thread/libcpu/f1c100s \
-Iuser

# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

LIBS = -lgcc -lc -lnosys -lm -u _printf_float
LIBDIR = 

ASFLAGS	= -Xassembler -mimplicit-it=thumb -c
LDFLAGS = $(MCU) -specs=nano.specs -T $(LDSCRIPT) $(LIBDIR) $(LIBS) -nostartfiles -Xlinker --gc-sections -Wl,--cref,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections
MCFLAGS	= $(CPU) $(FPU) $(FLOAT-ABI) -std=gnu99 $(C_DEFS) -ffunction-sections -fdata-sections -Wall $(OPT) -MMD

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin
#######################################
# build the application
#######################################
# list of objects
SDK_SRC		:=	$(foreach dir, $(SDK_DIR), $(wildcard $(dir)/*.c))
S_SRC		:=	$(foreach dir, $(S_DIR), $(wildcard $(dir)/*.S))
C_SRC		:=	$(foreach dir, $(C_DIR), $(wildcard $(dir)/*.c))

SDK_OBJ  = $(addprefix $(BUILD_DIR)/,$(notdir $(SDK_SRC:.c=.o)))
SDK_OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(S_SRC:.S=.o)))
OBJS  = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SRC:.c=.o)))

vpath %.c $(sort $(dir $(SDK_SRC) $(C_SRC)))
vpath %.S $(sort $(dir $(S_SRC)))
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@$(BIN) $< $@	
	@$(MKSUNXI) $@
	@echo building $(notdir $(<:.elf=.bin))

$(BUILD_DIR)/$(TARGET).elf: $(BUILD_DIR)/libsdk.a $(OBJS) Makefile
	@$(CC) $(OBJS) $(LDFLAGS) -o $@ $(BUILD_DIR)/libsdk.a
	@echo Linking...
	@$(SZ) $@
	
$(BUILD_DIR)/libsdk.a: $(SDK_OBJ) Makefile
	@echo Build libsdk.a
	@$(AR) $@ $(SDK_OBJ)

$(BUILD_DIR)/%.o: %.S Makefile | $(BUILD_DIR)
	@$(AS) $(ASFLAGS) $(MCFLAGS) -MF"$(@:%.o=%.d)" -MT $@ -c $< -o $@
	@echo assembling $(notdir $(<:.S=.S...))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	@$(CC) $(C_INCLUDES) $(MCFLAGS) -MF "$(@:%.o=%.d)" -MT $@ -c $< -o $@
	@echo compiling $(notdir $(<:.c=.c...))
	
$(BUILD_DIR):
	@mkdir $@		

clean:
	@echo Cleaning...
	@$(RM) $(BUILD_DIR) 

write:
	@tools/sunxi-fel -p spiflash-write 0 $(BUILD_DIR)/$(TARGET).bin
	@tools/xfel reset

mktool:
	cd tools/mksunxiboot && make
	cd tools/mksunxi && make

MKSUNXI		:=tools/mksunxi

mkboot:
	@$(MKSUNXI) $(BUILD_DIR)/$(TARGET).bin
  
#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)