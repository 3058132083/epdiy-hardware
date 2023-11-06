.PHONY: web

BOARDS = epdiy-v7 epdiy-v6 epdiy-v5 adapters/33pin_extension adapters/9.7_40_to_34_6inch helpers/40_pins_PCB_tester

web: build/web/index.html

.SECONDEXPANSION:
build/boards/%: $$*/$$(notdir $$*).kicad_pcb $$*/$$(notdir $$*).kicad_sch
	mkdir -p $(dir $@)
	kicad-cli sch export pdf $(word 2,$^) -o $@_schematic.pdf
	kicad-cli sch export python-bom $(word 2,$^) -o $@_BoM.xml
	xsltproc -o $@_BoM.csv present/bom2grouped_csv_jlcpcb.xsl $@_BoM.xml
	#
	kicad-cli pcb export pos $< --side front --format csv --units mm -o $@_top_pos.csv
	kicad-cli pcb export step --subst-models $< -o $@_model.step
	xz $@_model.step
	touch $@

build/web/index.html: README.md present/template/index.html $(addprefix build/boards/,$(BOARDS))
	mkdir -p build/web
	kikit present boardpage \
		-d $< \
		--name "EPDiy" \
		$(shell for board in ${BOARDS}; do echo -n "-b" $$board "\"\$$(cmark $$board/README.md)\"" "$$board/$$(basename $$board).kicad_pcb " ; done)  \
		--repository 'https://github.com/vroland/epdiy-hardware' \
		--template present/template/ \
		$$(for f in $$(find build/boards/ -type f); do echo "-r $$f"; done)  \
		build/web
