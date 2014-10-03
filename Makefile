.SUFFIXES: .coffee .js
COFFEE = coffee -c
FRONTCOFFEE = base.coffee eventEmitter.coffee util.coffee errors.coffee states.coffee keyEventManager.coffee model.coffee collection.coffee namespace.coffee widget.coffee widgetEnhancement.coffee templateManager.coffee restApiFactory.coffee #apiManager.coffee apiFactory.coffee router.coffee
FRONTJS = $(FRONTCOFFEE:.coffee=.js)
all : compiled/leaf.js #compiled/leaf.min.js

compiled/leaf.min.js : compiled/leaf.js
	@uglifyjs compiled/leaf.js > compiled/leaf.min.js
compiled/leaf.js : $(FRONTCOFFEE)
	@[ -f compiled/leaf.js ] && rm compiled/leaf.js  || echo clean
	@cd src;cat $(FRONTCOFFEE) | coffee -p -s > ../compiled/leaf.js -c ;cd ..;
	@echo done
$(FRONTJS) : %.js : %.coffee
	@echo generate $@
	$(COFFEE) -o compiled/part/ src/front-end/$<

$(FRONTCOFFEE):

