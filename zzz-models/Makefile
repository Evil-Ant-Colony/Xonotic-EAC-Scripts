
# Create config.mk in the same directory defining the following variables
# VERSION=_prefix1 will be overwritten, increasing the version number
# INSTALL_DIRS list of directories you want to copy the pk3s
# FILES files and directories to include in the pk3

MAKEFILE=$(firstword $(MAKEFILE_LIST))
NAME=$(notdir $(MAKEFILE_DIR))
MAKEFILE_DIR=$(patsubst /,,$(abspath $(dir $(MAKEFILE))))
CONFIG_MAKEFILE=$(MAKEFILE_DIR)/config.mk
include $(CONFIG_MAKEFILE)
ABS_FILES=$(addprefix $(MAKEFILE_DIR)/, $(FILES))
PK3=$(MAKEFILE_DIR)/$(NAME)$(VERSION).pk3
PACKAGE=$(PK3).serverpackage

.PHONY: all install increase_number clean pk3

all: install
all: increase_number

pk3: $(PK3)

$(PK3) : $(PACKAGE)
	( cd $(MAKEFILE_DIR) && zip -p $(patsubst $(MAKEFILE_DIR)/%,%, $(PK3) -r $(PACKAGE) $(FILES)) )

$(PACKAGE) : $(MAKEFILE)
$(PACKAGE) : $(FILES)
	echo Package $(NAME) >$(PACKAGE)

install: $(PK3)
	$(foreach d,$(INSTALL_DIRS), rm -f $(d)/$(NAME)*; cp $(PK3) $(d);)
	rm -f $(PK3) $(PACKAGE)

increase_number:
	bash -c 'let num=`echo $(VERSION) | sed -r "s/[^0-9]//g"`+1 ; sed -ri "s/^(VERSION=[^0-9]+)[0-9]+/\1$$num/" $(CONFIG_MAKEFILE);'
