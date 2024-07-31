# See LICENSE file for copyright and license details
# Takum-HDL - takum VHDL implementation
.POSIX:
.SUFFIXES:

include config.mk

RTL =\
	rtl/decoder/characteristic_determinator\
	rtl/decoder/common_decoder\
	rtl/decoder/decoder_linear\
	rtl/decoder/decoder_logarithmic\
	rtl/encoder/common_encoder\
	rtl/encoder/encoder_linear\
	rtl/encoder/encoder_logarithmic\
	rtl/encoder/leading_zero_counter_8\
	rtl/encoder/rounder\
	rtl/encoder/underflow_overflow_predictor\

SIMULATION =\
	simulation/decoder/common_decoder_tb\
	simulation/encoder/common_encoder_tb\

all:

format:
	$(VSG) --fix --configuration .vsg-format.yaml --filename $(RTL:=.vhd) $(SIMULATION:=.vhd)
