encode:
	gcc arith_encoder.c -o enc
	./enc 0

decode:
	gcc arith_decoder.c -o dec
	./dec 0

dec_reset:
	gcc arith_decoder.c -o dec
	./dec 1

enc_reset:
	gcc arith_encoder.c -o enc
	./enc 1

bitstream_converter:
	python binary_bitstream_generator.py

range_analyzer_converter:
	python binary_range_converter.py

comp_ref:
	python3 check_bitstream_vs_ref.py

comp_logic:
	python3 new_logic/comparer.py
