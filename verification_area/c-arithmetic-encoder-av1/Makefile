ob:
	gcc arith_encoder.c ob_bitstream.c header.h -o arith
	./arith 1

normal:
	gcc arith_encoder.c ob_bitstream.c header.h -o arith
	./arith 0

converter:
	python binary_bitstream_generator.py
