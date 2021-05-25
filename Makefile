### Variables #######################################################
# Files and directories.
MAKEFILE_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PROJECT_ROOT = .
DOCKER_STUB = $(PROJECT_ROOT)/.docker_stub

# Shell commands.
AWK = awk
CP = cp -vf
GIT = git
GREP = grep
RM = rm -vf
SED = sed
TAR = tar -v
TARCF = $(TAR) --owner=root --group=root -cf
TR = tr

# Variables that influence the build process.
include $(PROJECT_ROOT)/Makefile.vars


### Functions #######################################################
# Prints the addresses of available containers.
define containers_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .IPv4Address }} {{ end }}")
endef

# Prints name:address pairs for the available containers.
define containers_name_addr
$(shell docker network inspect bridge -f "{{ range .Containers }}{{ .Name }}:{{ .IPv4Address }} {{ end }}")
endef

# Prints the names of the last $2 containers that exited with status $1.
define containers_name_exited
$(shell docker container ls --last $(2) -f "exited=$(1)" -f "ancestor=$(IMAGE_NAME)" --format "{{ .Names }}")
endef

# Returns the paths to the enabled SystemRescue modules.
define mod_dirs
$(addprefix $(SRM_SRC_LOCAL)/,$(SRM_ENABLED))
endef


### Targets and recipes #############################################
.ONESHELL:

.PHONY: all help \
	build-docker build-sr copy-sr build-srm \
	srm-pkg clean-files clean-ssh clean-docker clean-srm-pkg lsaddr lscont lsimg

all: build-docker

$(DOCKER_STUB): Dockerfile $(PROJECT_ROOT)/Makefile.vars $(SRM_TAR)
	@printf "Changed files: %s\n" "$(?)"
	docker build . -t $(IMAGE_NAME) \
		--build-arg sr_src="$(SR_SRC)" \
		--build-arg sr_src_local="$(SR_SRC_LOCAL)" \
		--build-arg sr_archiso_rev="$(SR_ARCHISO_REV)" \
		\
		--build-arg srm_src="$(SRM_SRC)" \
		--build-arg srm_src_local="$(SRM_TAR)" \
		--build-arg srm_enabled="$(SRM_ENABLED)" \
		\
		--build-arg image_maintainer="$(IMAGE_MAINTAINER)" \
		--build-arg image_description="$(IMAGE_DESCRIPTION)" \
		--build-arg image_version="$(IMAGE_VERSION)"
	touch $(@)

##-------------------------------------------------------------------
##- Common targets
##-------------------------------------------------------------------
build-docker: $(DOCKER_STUB)	##- build or refresh the docker image

build-sr: build-docker	##- start a new container and build the SystemRescue image
	docker run --net=test --privileged -i -t "$(IMAGE_NAME)" "./build.sh"

copy-sr: build-sr	##- copy the last successfully created SystemRescue image
	docker cp $(call containers_name_exited,0,1):"$(SR_SRC)/out/" .

help:		##- show this help
	@$(SED) -e '/#\{2\}-/!d; s/\\$$//; s/:[^#\t]*/:/; s/#\{2\}- *//' $(MAKEFILE_LIST)

$(SRM_TAR): $(call mod_dirs) Makefile.vars
	$(TARCF) $(@) -C "$(SRM_SRC_LOCAL)" $(SRM_ENABLED) srm-bootstrap.sh

build-srm: clean-srm $(SRM_TAR)

##-
##-------------------------------------------------------------------
##- Container utilities
##-------------------------------------------------------------------
ctest:		##- start a new container using IMAGE_NAME
	docker run --net=test --privileged \
		--mount "type=bind,src=$(realpath $(SR_SRC_LOCAL)),dst=$(SR_SRC)_" \
		-i -t "$(IMAGE_NAME)"

ctest-%:	##- start a new container with the specified name using IMAGE_NAME
	docker run --net=test --privileged \
		--name $(*) -h $(*) \
		--mount "type=bind,src=$(realpath $(SR_SRC_LOCAL)),dst=$(SR_SRC)_" \
		-i -t "$(IMAGE_NAME)"

csh:		##- start a root shell in a new container using IMAGE_NAME
	docker run --net=test --privileged \
		--mount "type=bind,src=$(realpath $(SR_SRC_LOCAL)),dst=$(SR_SRC)_" \
		-i -u root -t "$(IMAGE_NAME)" \
		/bin/bash -l

cush:		##- start a shell in a new container using IMAGE_NAME
	docker run --net=test --privileged \
		--mount "type=bind,src=$(realpath $(SR_SRC_LOCAL)),dst=$(SR_SRC)_" \
		-i -u builder -t "$(IMAGE_NAME)" \
		/bin/bash -l

sh-%:
	@docker exec -t -u root -i $(*) bash -l

ush-%:
	@docker exec -t -u builder -i $(*) bash -l


##-
##-------------------------------------------------------------------
##- Docker utilities
##-------------------------------------------------------------------
lsimg:		##- list available docker images
	@docker image list

lscont:		##- list available docker containers
	@docker container list

lsaddr:		##- list IP addresses of available docker containers (?)
	@echo $(containers_name_addr) | $(SED) -E 's/ /\n/g' | \
		$(AWK) -F'[/:]' '{printf("%-20s %s\n", $$1, $$2);}'

##-
##-------------------------------------------------------------------
##- Cleanup
##-------------------------------------------------------------------
clean-docker:	##- cleanup docker containers and images
	docker container prune -f
	docker image prune -f

clean-files:	##- clean files generated during the build process
	make -C $(DOCKER_BOOTSTRAP) clean

clean-srm-pkg:
	$(RM) $(SRM_BUILD_PACKAGES)

clean-srm-tar:
	$(RM) $(SRM_TAR)

clean-ssh:	##- remove entries for existing containers from your ssh known_hosts file
	$(foreach ip,$(call containers_addr),__a="$(ip)"; ssh-keygen -R $${__a%%/*};)
