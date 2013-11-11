// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  (function(Leaf) {
    var List, Util, Widget,
      _this = this;
    Util = Leaf.Util;
    Widget = (function(_super) {
      __extends(Widget, _super);

      function Widget(template) {
        this.template = template;
        Widget.__super__.constructor.call(this);
        this.node = null;
        this.$node = null;
        this.node$ = null;
        this.nodes = [];
        this.UI = {};
        Widget.instances.push(this);
        if (!template) {
          return;
        }
        this.initTemplate(this.template);
      }

      Widget.prototype.initTemplate = function(template, option) {
        var node, tempNode, _i, _len, _ref;
        if (!template) {
          throw "invalid template " + template;
        }
        this.nodes = [];
        if (typeof template === "string") {
          if ((template.indexOf("#")) === 0) {
            this.node = document.getElementById(template.substring(1));
            if (!this.node) {
              console.error("template of id", template.substring(1), "not found");
              return;
            }
            this.nodes = [this.node];
            this.node.widget = this;
          } else {
            tempNode = document.createElement("div");
            tempNode.innerHTML = template.trim();
            this.node = tempNode.children[0];
            _ref = tempNode.children;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              node = _ref[_i];
              this.nodes.push(node);
              node.widget = this;
            }
          }
        } else if (Util.isHTMLNode(template)) {
          this.node = template;
          this.node.widget = this;
          this.nodes.push(template);
        }
        if (!this.node) {
          throw "invalid template " + template;
        }
        if (typeof $ === "function") {
          this.$node = $(this.node);
          this.node$ = this.$node;
        }
        this.initUI();
        this.initData();
        this.initSubWidgets();
        return Widget.emit("widget", this);
      };

      Widget.prototype.initData = function() {
        var name, _results,
          _this = this;
        if (!this.Data) {
          this.Data = {};
        }
        _results = [];
        for (name in this.Data) {
          if (!this.UI[name]) {
            console.debug("useless widget data " + name);
            continue;
          }
          _results.push((function() {
            var value;
            value = _this.Data[name];
            Object.defineProperty(_this.Data, name, {
              set: function(newValue) {
                _this._asignValueToDom(name, newValue);
                return value = newValue;
              },
              get: function() {
                return value;
              }
            });
            if (value) {
              return _this.Data[name] = value;
            } else {
              return _this.Data[name] = _this.UI[name].innerText;
            }
          })());
        }
        return _results;
      };

      Widget.prototype._asignValueToDom = function(name, value) {
        var dom;
        if (!this.UI[name]) {
          throw "invalid UI '" + name + "'";
        }
        dom = this.UI[name];
        if (typeof value === "string" in value instanceof String) {
          this.UI[name].innerText = value;
        }
      };

      Widget.prototype.initSubWidgets = function() {
        var index, item, name, node, widget, widgets, _i, _j, _len, _len1, _ref, _results, _widgets;
        _ref = this.nodes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          widgets = node.getElementsByTagName("widget");
          _widgets = [];
          for (_j = 0, _len1 = widgets.length; _j < _len1; _j++) {
            item = widgets[_j];
            _widgets.push(item);
          }
          widgets = _widgets;
          _results.push((function() {
            var _k, _len2, _results1;
            _results1 = [];
            for (index = _k = 0, _len2 = widgets.length; _k < _len2; index = ++_k) {
              widget = widgets[index];
              name = widget.getAttribute("data-widget");
              if (!name) {
                continue;
              }
              if (this[name] instanceof Widget) {
                _results1.push(this[name].replace(widget));
              } else if (this[name]) {
                console.error("Widget named " + name + " isnt isn't instanceof Widget");
                _results1.push(console.trace());
              } else {
                console.error("Widget named", name, "not exists for", widget);
                _results1.push(console.trace());
              }
            }
            return _results1;
          }).call(this));
        }
        return _results;
      };

      Widget.prototype.initUI = function() {
        var elem, elems, id, node, subNode, _elems, _i, _j, _k, _len, _len1, _len2, _ref;
        if (!this.nodes) {
          throw "invalid root " + this.nodes;
        }
        _ref = this.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          elems = node.getElementsByTagName("*");
          _elems = [node];
          for (_j = 0, _len1 = elems.length; _j < _len1; _j++) {
            elem = elems[_j];
            _elems.push(elem);
          }
          elems = _elems;
          for (_k = 0, _len2 = elems.length; _k < _len2; _k++) {
            subNode = elems[_k];
            if (subNode.tagName.toLowerCase() === "widget") {
              continue;
            }
            if (id = subNode.getAttribute("data-id")) {
              this.UI[id] = subNode;
              subNode.widget = this;
              this._delegateEventForControl(id);
              if (typeof $ === "function") {
                this.UI[id + "$"] = this.UI["$" + id] = $(subNode);
              }
            }
          }
        }
        this._delegateEventForControl();
        return true;
      };

      Widget.prototype._delegateEventForControl = function(id) {
        var event, events, node, _i, _len, _results,
          _this = this;
        events = ["blur", "click", "focus", "keydown", "keyup", "keypress", "mousemove", "mouseenter", "mouseleave", "mouseover", "mouseout", "scroll"];
        node = this.UI[id];
        if (!node) {
          node = this.node;
          id = "node";
        }
        _results = [];
        for (_i = 0, _len = events.length; _i < _len; _i++) {
          event = events[_i];
          _results.push((function(event) {
            return node["on" + event] = function(e) {
              if (typeof _this["on" + Util.capitalize(event) + Util.capitalize(id)] === "function") {
                return _this["on" + Util.capitalize(event) + Util.capitalize(id)](e);
              }
              return true;
            };
          })(event));
        }
        return _results;
      };

      Widget.prototype.appendTo = function(target) {
        var node, _i, _j, _len, _len1, _ref, _ref1, _results;
        if (Util.isHTMLElement(target)) {
          _ref = this.nodes;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            target.appendChild(node);
          }
          return true;
        }
        if (target instanceof Leaf.Widget) {
          _ref1 = this.nodes;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            node = _ref1[_j];
            _results.push(target.node.appendChild(node));
          }
          return _results;
        }
      };

      Widget.prototype.replace = function(target) {
        this.before(target);
        if (target instanceof Leaf.Widget) {
          target.remove();
          return;
        }
        if (Util.isHTMLElement(target) && target.parentElement) {
          target.parentElement.removeChild(target);
        }
      };

      Widget.prototype.prependTo = function(target) {
        var first, node, _i, _j, _len, _len1, _ref, _ref1;
        if (Util.isHTMLElement(target)) {
          target = target;
        } else if (target instanceof Leaf.Widget) {
          target = target.node;
        } else {
          return false;
        }
        if (target.children.length === 0) {
          _ref = this.nodes;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            target.appendChild(node);
          }
        } else {
          this.nodes.reverse();
          first = target.children[0];
          _ref1 = this.nodes;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            node = _ref1[_j];
            target.insertBefore(node, first);
          }
          this.nodes.reverse();
        }
        return true;
      };

      Widget.prototype.remove = function() {
        var node, _i, _len, _ref, _results;
        _ref = this.nodes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.parentElement) {
            _results.push(node.parentElement.removeChild(node));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      Widget.prototype.after = function(target) {
        var node, _i, _j, _len, _len1, _ref, _ref1, _results, _results1;
        if (Util.isHTMLElement(target)) {
          target = target;
        } else if (target instanceof Leaf.Widget) {
          target = target.node;
        } else {
          console.error("Insert unknow Object", target);
          return false;
        }
        if (!target || !target.parentElement) {
          console.log(target, target.parentElement);
          console.error("can't insert befere root element ");
          return false;
        }
        if (target.nextElementSibling) {
          _ref = this.nodes;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            _results.push(target.parentElement.insertBefore(node, target.nextElementSibling));
          }
          return _results;
        } else {
          _ref1 = this.nodes;
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            node = _ref1[_j];
            _results1.push(target.parentElement.appendChild(node));
          }
          return _results1;
        }
      };

      Widget.prototype.before = function(target) {
        var node, _i, _len, _ref;
        if (Util.isHTMLElement(target)) {
          target = target;
        } else if (target instanceof Leaf.Widget) {
          target = target.node;
        } else {
          console.error("Insert unknow Object,target");
          return false;
        }
        if (!target || !target.parentElement) {
          console.error("can't insert befere root element ");
          return false;
        }
        _ref = this.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          target.parentElement.insertBefore(node, target);
        }
        this.nodes.reverse();
        return true;
      };

      Widget.prototype.occupy = function(target) {
        if (Util.isHTMLElement(target)) {
          target.innerHTML = "";
        }
        if (target instanceof Leaf.Widget) {
          target.node.innerHTML = "";
        }
        return this.appendTo(target);
      };

      return Widget;

    })(Leaf.EventEmitter);
    List = (function(_super) {
      __extends(List, _super);

      function List(template, create) {
        var _this = this;
        List.__super__.constructor.call(this, template);
        this.init(create);
        Object.defineProperty(this, "length", {
          get: function() {
            return _this._length;
          },
          set: function(value) {
            var index, _i, _ref;
            if (value > _this._length) {
              throw "can't asign length larger than the origin";
            }
            if (value < 0) {
              throw "can't asign length lesser than 0";
            }
            if (typeof value !== "number") {
              throw new TypeError();
            }
            for (index = _i = value, _ref = _this.length; value <= _ref ? _i < _ref : _i > _ref; index = value <= _ref ? ++_i : --_i) {
              _this[index].remove();
              delete _this[index];
            }
            return _this._length = value;
          }
        });
      }

      List.prototype.init = function(create) {
        var _this = this;
        this.create = create || this.create || function(item) {
          return item;
        };
        this._length = 0;
        return this.node.innerHTML = "";
      };

      List.prototype.check = function(item) {
        var child, _i, _len, _results;
        if (!(item instanceof Widget)) {
          throw "Leaf List only accept widget as element";
        }
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          child = this[_i];
          if (child === item) {
            throw "already exists";
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      List.prototype.indexOf = function(item) {
        var child, index, _i, _len;
        for (index = _i = 0, _len = this.length; _i < _len; index = ++_i) {
          child = this[index];
          if (item === child) {
            return index;
          }
        }
        return -1;
      };

      List.prototype.push = function(item) {
        item = this.create(item);
        this.check(item);
        this[this._length] = item;
        this._length++;
        item.appendTo(this.node);
        item.parentList = this;
        this.emit("add", item);
        return this._length;
      };

      List.prototype.pop = function() {
        var item;
        if (this._length === 0) {
          return null;
        }
        this._length -= 1;
        item = this[this._length];
        delete this[this._length];
        item.remove();
        this.emit("remove", item);
        item.parentList = null;
        return item;
      };

      List.prototype.unshift = function(item) {
        var index, _i, _ref;
        item = this.create(item);
        this.check(item);
        if (this._length === 0) {
          item.appendTo(this.node);
          this[0] = item;
          return 1;
        }
        for (index = _i = _ref = this._length; _ref <= 1 ? _i <= 1 : _i >= 1; index = _ref <= 1 ? ++_i : --_i) {
          this[index] = this[index - 1];
        }
        this[0] = item;
        this._length += 1;
        item.prependTo(this.node);
        this.emit("add", item);
        item.parentList = this;
        return this._length;
      };

      List.prototype.removeItem = function(item) {
        var index;
        index = this.indexOf(item);
        if (index < 0) {
          return index;
        }
        this.splice(index, 1);
        item.parentList = null;
        this.emit("remove", item);
        return item;
      };

      List.prototype.shift = function() {
        var index, result, _i, _ref;
        result = this[0];
        for (index = _i = 0, _ref = this._length - 1; 0 <= _ref ? _i < _ref : _i > _ref; index = 0 <= _ref ? ++_i : --_i) {
          this[index] = this[index + 1];
        }
        result.remove();
        this.emit("remove", result);
        result.parentList = null;
        return result;
      };

      List.prototype.splice = function() {
        var achor, count, increase, index, item, offset, origin, result, toAdd, toAddFinal, _i, _j, _k, _l, _len, _len1, _len2, _m, _n, _ref, _ref1, _ref2, _ref3;
        index = arguments[0], count = arguments[1], toAdd = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        result = [];
        if (typeof count === "undefined" || index + count > this._length) {
          count = this._length - index;
        }
        for (offset = _i = 0; 0 <= count ? _i < count : _i > count; offset = 0 <= count ? ++_i : --_i) {
          item = this[index + offset];
          item.remove();
          this.emit("remove", item);
          item.parentList = null;
          result.push(item);
        }
        toAddFinal = (function() {
          var _j, _len, _results;
          _results = [];
          for (_j = 0, _len = toAdd.length; _j < _len; _j++) {
            item = toAdd[_j];
            _results.push(this.create(item));
          }
          return _results;
        }).call(this);
        if (index === 0) {
          for (_j = 0, _len = toAddFinal.length; _j < _len; _j++) {
            item = toAddFinal[_j];
            this.check(item);
            item.prependTo(this.node);
            this.emit("add", item);
            item.parentList = this;
          }
        } else {
          achor = this[index - 1];
          for (_k = 0, _len1 = toAddFinal.length; _k < _len1; _k++) {
            item = toAddFinal[_k];
            this.check(item);
            item.after(achor);
            this.emit("add", item);
            item.parentList = this;
          }
        }
        increase = toAddFinal.length - count;
        if (increase < 0) {
          for (origin = _l = _ref = index + count, _ref1 = this._length; _ref <= _ref1 ? _l < _ref1 : _l > _ref1; origin = _ref <= _ref1 ? ++_l : --_l) {
            this[origin + increase] = this[origin];
          }
        } else if (increase > 0) {
          for (origin = _m = _ref2 = this._length - 1, _ref3 = index + count - 1; _ref2 <= _ref3 ? _m < _ref3 : _m > _ref3; origin = _ref2 <= _ref3 ? ++_m : --_m) {
            this[origin + increase] = this[origin];
          }
        }
        for (offset = _n = 0, _len2 = toAddFinal.length; _n < _len2; offset = ++_n) {
          item = toAddFinal[offset];
          this[index + offset] = item;
        }
        this._length += increase;
        return result;
      };

      List.prototype.slice = function(from, to) {
        return this.toArray().slice(from, to);
      };

      List.prototype.forEach = function(handler) {
        var item, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          item = this[_i];
          _results.push(handler(item));
        }
        return _results;
      };

      List.prototype.toArray = function() {
        var item;
        return (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = this.length; _i < _len; _i++) {
            item = this[_i];
            _results.push(item);
          }
          return _results;
        }).call(this);
      };

      List.prototype.syncWith = function(arr, converter) {
        var finalArr, index, item, _, _i, _j, _k, _len, _len1, _ref;
        if (converter == null) {
          converter = function(item) {
            return item;
          };
        }
        finalArr = [];
        for (index = _i = 0, _len = arr.length; _i < _len; index = ++_i) {
          item = arr[index];
          _ = converter(item);
          if (!(_ instanceof Widget)) {
            throw "sync of invalid widget at index:" + index;
          }
          finalArr.push(_);
        }
        for (index = _j = 0, _ref = this._length; 0 <= _ref ? _j < _ref : _j > _ref; index = 0 <= _ref ? ++_j : --_j) {
          this.emit("remove", this[index]);
          this[index].parentList = null;
          delete this[index];
        }
        this.node.innerHTML = "";
        for (index = _k = 0, _len1 = finalArr.length; _k < _len1; index = ++_k) {
          item = finalArr[index];
          this[index] = item;
          item.appendTo(this.node);
          this.emit("add", item);
          item.parentList = this;
        }
        this._length = finalArr.length;
        return this;
      };

      List.prototype.sort = function(judge) {
        return this.sync(this.toArray().sort(judge));
      };

      return List;

    })(Widget);
    Widget.List = List;
    Widget.makeList = function(node, create) {
      return new Widget.List(node, create);
    };
    Widget.Event = new Leaf.EventEmitter();
    Widget.on = function() {
      return this.Event.on.apply(this.Event, arguments);
    };
    Widget.emit = function() {
      return this.Event.emit.apply(this.Event, arguments);
    };
    Widget.instances = [];
    return Leaf.Widget = Widget;
  })(this.Leaf);

}).call(this);
