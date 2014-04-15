.SUFFIXES: .coffee .js
COFFEE = coffee -c
FRONTCOFFEE = base.coffee eventEmitter.coffee util.coffee keyEventManager.coffee model.coffee collection.coffee widget.coffee widgetEnhancement.coffee templateManager.coffee #apiManager.coffee apiFactory.coffee router.coffee
FRONTJS = $(FRONTCOFFEE:.coffee=.js)
all : compiled/leaf.js compiled/leaf.min.js

compiled/leaf.min.js : compiled/leaf.js
	@uglifyjs compiled/leaf.js > compiled/leaf.min.js
compiled/leaf.js : $(FRONTCOFFEE)
	@[ -f compiled/leaf.js ] && rm compiled/leaf.js  || echo clean
	@cd src;coffee -j ../compiled/leaf.js -c $(FRONTCOFFEE);cd ..;
	@echo done
$(FRONTJS) : %.js : %.coffee
	@echo generate $@
	$(COFFEE) -o compiled/part/ src/front-end/$<

$(FRONTCOFFEE):
