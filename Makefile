PROJ_NAME = stm32f4

################################################################################
#                   SETUP TOOLS                                                #
################################################################################

export SOURCES_ROOT = `pwd` 
DOWNLOAD_DIR = external

TOOLS_DIR = ./gcc-arm-none-eabi-4_8-2013q4/bin

CC      = $(TOOLS_DIR)/arm-none-eabi-gcc
OBJCOPY = $(TOOLS_DIR)/arm-none-eabi-objcopy
GDB     = $(TOOLS_DIR)/arm-none-eabi-gdb
AS      = $(TOOLS_DIR)/arm-none-eabi-as

##### Preprocessor options

# directories to be searched for header files
INCLUDE = $(addprefix -I,$(INC_DIRS))

# #defines needed when working with the STM peripherals library
DEFS    = -DUSE_STDPERIPH_DRIVER
# DEFS   += -DUSE_FULL_ASSERT

##### Assembler options

AFLAGS  = -mcpu=cortex-m4 
AFLAGS += -mthumb
AFLAGS += -mthumb-interwork
AFLAGS += -mlittle-endian
AFLAGS += -mfloat-abi=hard
AFLAGS += -mfpu=fpv4-sp-d16

##### Compiler options

CFLAGS  = -ggdb
CFLAGS += -O0
CFLAGS += -Wall -Wextra -Warray-bounds
CFLAGS += $(AFLAGS)

##### Linker options

# tell ld which linker file to use
# (this file is in the current directory)
LFLAGS  = -Tstm32_flash.ld


################################################################################
#                   SOURCE FILES DIRECTORIES                                   #
################################################################################

STM_ROOT         = STM32F4-Discovery_FW_V1.1.0

STM_SRC_DIR      = $(STM_ROOT)/Libraries/STM32F4xx_StdPeriph_Driver/src
STM_SRC_DIR     += $(STM_ROOT)/Utilities/STM32F4-Discovery
STM_STARTUP_DIR += $(STM_ROOT)/Libraries/CMSIS/ST/STM32F4xx/Source/Templates/TrueSTUDIO

vpath %.c $(STM_SRC_DIR)
vpath %.s $(STM_STARTUP_DIR)


################################################################################
#                   HEADER FILES DIRECTORIES                                   #
################################################################################

# The header files we use are located here
INC_DIRS  = $(STM_ROOT)/Utilities/STM32F4-Discovery
INC_DIRS += $(STM_ROOT)/Libraries/CMSIS/Include
INC_DIRS += $(STM_ROOT)/Libraries/CMSIS/ST/STM32F4xx/Include
INC_DIRS += $(STM_ROOT)/Libraries/STM32F4xx_StdPeriph_Driver/inc

#TODO: add other libs
#STM32_USB_Device_Library
#STM32_USB_HOST_Library
#STM32_USB_OTG_Driver

INC_DIRS += .


################################################################################
#                   SOURCE FILES TO COMPILE                                    #
################################################################################

SRCS  += main.c
SRCS  += system_stm32f4xx.c
#TODO: add stm32f4xx[*].c
SRCS  += stm32f4xx_rcc.c
SRCS  += stm32f4xx_gpio.c
SRCS  += stm32f4xx_tim.c
SRCS  += misc.c

# startup file, calls main
ASRC  = startup_stm32f4xx.s

OBJS  = $(SRCS:.c=.o)
OBJS += $(ASRC:.s=.o)


######################################################################
#                         SETUP TARGETS                              #
######################################################################

.PHONY: all

all: $(PROJ_NAME).elf


%.o : %.c
	@echo "[Compiling  ]  $^"
	@$(CC) -c -o $@ $(INCLUDE) $(DEFS) $(CFLAGS) $^

%.o : %.s
	@echo "[Assembling ]" $^
	@$(AS) $(AFLAGS) $< -o $@


$(PROJ_NAME).elf: $(OBJS)
	@echo "[Linking    ]  $@"
	@$(CC) $(CFLAGS) $(LFLAGS) $^ -o $@ 
	@$(OBJCOPY) -O ihex $(PROJ_NAME).elf   $(PROJ_NAME).hex
	@$(OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin

clean:
	rm -f *.o $(PROJ_NAME).elf $(PROJ_NAME).hex $(PROJ_NAME).bin

cleanall:
	rm -f *.o $(PROJ_NAME).elf $(PROJ_NAME).hex $(PROJ_NAME).bin $(DOWNLOAD_DIR)

flash: all
	st-flash write $(PROJ_NAME).bin 0x8000000

debug:
# before you start gdb, you must start st-util
	$(GDB) -tui $(PROJ_NAME).elf

# download toolchain and stm32 libs
download: \
	$(DOWNLOAD_DIR)/stsw-stm32068.zip \
	$(DOWNLOAD_DIR)/gcc-arm-none-eabi.tar.bz2 \

$(DOWNLOAD_DIR)/stsw-stm32068.zip:
	mkdir -p $(DOWNLOAD_DIR)
	cd $(DOWNLOAD_DIR) && wget http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stsw-stm32068.zip

$(DOWNLOAD_DIR)/gcc-arm-none-eabi.tar.bz2:
	mkdir -p $(DOWNLOAD_DIR)
	cd $(DOWNLOAD_DIR) && wget https://launchpad.net/gcc-arm-embedded/4.8/4.8-2013-q4-major/+download/gcc-arm-none-eabi-4_8-2013q4-20131204-linux.tar.bz2

extract: stsw-stm32068 gcc-arm-none-eabi

stsw: $(DOWNLOAD_DIR)/stsw-stm32068.zip
	unzip $(DOWNLOAD_DIR)/stsw-stm32068.zip

gcc: $(DOWNLOAD_DIR)/gcc-arm-none-eabi.tar.bz2
	tar jxvf $(DOWNLOAD_DIR)/gcc-arm-none-eabi*.tar.bz2

init: stsw gcc
