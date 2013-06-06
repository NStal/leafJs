// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function(Leaf) {
    var Util, Widget;
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
        this.initSubWidgets();
        return Widget.emit("widget", this);
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
        events = ["blur", "click", "focus", "keydown", "keyup", "keypress", "mousemove", "mouseenter", "mouseleave", "mouseover", "mouseout"];
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
        var node, _i, _len, _ref;
        _ref = this.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.parentElement) {
            node.parentElement.removeChild(node);
          }
        }
        return this.emit("remove");
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
          console.log(target, target.parentElement);
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

    })(Leaf.Observable);
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
