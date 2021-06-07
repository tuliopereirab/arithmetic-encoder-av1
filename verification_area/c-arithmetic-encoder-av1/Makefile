normal:
	gcc arith_encoder.c -o arith
	./arith 0

reset:
	gcc arith_encoder.c -o arith
	./arith 1

bitstream_converter:
	python binary_bitstream_generator.py

range_analyzer_converter:
	python binary_range_converter.py

comp:
	python3 check_bitstream.py
