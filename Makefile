
ICESID_SRCS     = dac.v sid.v env.v voice.v filter.v clip.v pot.v mult.v output.v
ALL_ICESID_SRCS = $(addprefix icesid/,$(ICESID_SRCS))
PORTABLE_ICESID_SRCS = portable/SB_MAC16.v
VERILATOR        ?= verilator
BOARD           = reDIP-SID

ifeq ($(BOARD),reDIP-SID)
	include reDIP-SID/Makefile.mk
else
	include icesugar/Makefile.mk
endif

clean:
	rm -rf $(BUILD_DIR) obj_dir

test: $(BUILD_DIR)/mult_tb_obj/mult_tb test-portable
	$<

test-portable:
	$(VERILATOR) --lint-only --top-module sid -GPOT_SUPPORT=0 $(ALL_ICESID_SRCS) $(PORTABLE_ICESID_SRCS)

$(BUILD_DIR)/mult_tb_obj/mult_tb: tests/mult_tb.sv icesid/mult.v icesid/clip.v $(PORTABLE_ICESID_SRCS)
	@mkdir -p $(@D)
	$(VERILATOR) --binary --timing --assert --top-module mult_tb --Mdir $(@D) -o $(notdir $@) $^

.SECONDARY:
.PHONY: all clean test test-portable
