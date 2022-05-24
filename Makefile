
ICESID_SRCS     = dac.v sid.v env.v voice.v filter.v clip.v pot.v mult.v output.v
ALL_ICESID_SRCS = $(addprefix icesid/,$(ICESID_SRCS))
BOARD           = reDIP-SID

ifeq ($(BOARD),reDIP-SID)
	include reDIP-SID/Makefile.mk
else
	include icesugar/Makefile.mk
endif

clean:
	rm -rf $(BUILD_DIR) obj_dir

.SECONDARY:
.PHONY: all clean
