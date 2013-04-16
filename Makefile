.SUFFIXES: .coffee .js
COFFEE = coffee -c
FRONTCOFFEE = base.coffee util.coffee widget.coffee templateManager.coffee apiManager.coffee apiFactory.coffee router.coffee
FRONTJS = $(FRONTCOFFEE:.coffee=.js)
all : compiled/leaf.js

compiled/leaf.js : $(FRONTJS)
	@[ -f compiled/leaf.js ] && rm compiled/leaf.js  || echo clean
	@for jsfile in $(FRONTJS); do cat compiled/front-end/$$jsfile >> compiled/leaf.js; done
	@echo done

$(FRONTJS) : %.js : %.coffee
	@echo generate $@
	$(COFFEE) -o compiled/front-end/ src/front-end/$<

$(FRONTCOFFEE):

