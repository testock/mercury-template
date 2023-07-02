MC=mmc
MLFLAGS=
ALL: mercury_template

mercury_template: mercury_template.m
	$(MC) --make $(MLFLAGS) mercury_template

clean:
	$(MC) --make clean

.PHONY: ALL clean
