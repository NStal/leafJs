.SUFFIXES: .coffee .js
COFFEE = coffee -c
FRONTCOFFEE = base.coffee util.coffee widget.coffee templateManager.coffee apiManager.coffee apiFactory.coffee router.coffee
FRONTJS = $(FRONTCOFFEE:.coffee=.js)
all : compiled/leaf.js

compiled/leaf.js : $(FRONTCOFFEE)
	@[ -f compiled/leaf.js ] && rm compiled/leaf.js  || echo clean
	@cd src;coffee -j ../compiled/leaf.js -c $(FRONTCOFFEE);cd ..;
	@echo done

$(FRONTJS) : %.js : %.coffee
	@echo generate $@
	$(COFFEE) -o compiled/part/ src/front-end/$<

$(FRONTCOFFEE):

