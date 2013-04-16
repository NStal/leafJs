// Generated by CoffeeScript 1.4.0
(function() {
  var __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  (function(Leaf) {
    var EventEmitter, Key, KeyEventManager, Mouse, Observable, Util;
    EventEmitter = (function() {

      function EventEmitter() {
        this.events = {};
        this.trigger = this.emit;
        this.bind = this.on;
      }

      EventEmitter.prototype.on = function(event, callback, context) {
        var handler, handlers;
        handlers = this.events[event] = this.events[event] || [];
        handler = {
          callback: callback,
          option: {
            context: context
          }
        };
        handlers.push(handler);
        return this;
      };

      EventEmitter.prototype.emit = function() {
        var event, handler, params, _i, _len, _ref, _results;
        event = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (this.events[event]) {
          _ref = this.events[event];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            handler = _ref[_i];
            _results.push(handler.callback.apply(handler.option && handler.option.context || this, params));
          }
          return _results;
        }
      };

      return EventEmitter;

    })();
    Util = {};
    Util.isHTMLElement = function(template) {
      if (typeof HTMLElement === "object" && template instanceof HTMLElement || (template && typeof template === "object" && template.nodeType === 1 && typeof template.nodeName === "string")) {
        return true;
      }
      return false;
    };
    Util.isHTMLNode = function(o) {
      return (typeof Node === "object" && o instanceof Node) || o && typeof o === "object" && typeof o.nodeType === "number" && typeof o.nodeName === "string";
    };
    Util.isMobile = function() {
      if (navigator && navigator.userAgent) {
        return (navigator.userAgent.match(/Android/i) || navigator.userAgent.match(/webOS/i) || navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPad/i) || navigator.userAgent.match(/iPod/i) || navigator.userAgent.match(/BlackBerry/i) || navigator.userAgent.match(/Windows Phone/i)) && true;
      } else {
        return false;
      }
    };
    Util.getBrowserInfo = function() {
      var M, N, tem, ua;
      N = navigator.appName;
      ua = navigator.userAgent;
      M = ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
      tem = ua.match(/version\/([\.\d]+)/i);
      if (M && tem !== null) {
        M[2] = tem[1];
      }
      M = M ? [M[1],M[2]] : [N, navigator.appVersion, '-?'];
      return {
        name: M[0],
        version: M[1]
      };
    };
    Util.capitalize = function(string) {
      return string.charAt(0).toUpperCase() + string.slice(1);
    };
    KeyEventManager = (function(_super) {

      __extends(KeyEventManager, _super);

      function KeyEventManager() {
        KeyEventManager.__super__.constructor.call(this);
        KeyEventManager.instances.push(this);
        this.isActive = false;
        return;
      }

      KeyEventManager.prototype.attachTo = function(node) {
        var _this = this;
        this.attachment = node;
        $(this.attachment).keydown(function(e) {
          e.capture = function() {
            this.catchEvent = false;
            this.preventDefault();
            return this.stopImmediatePropagation();
          };
          if (_this.isActive && KeyEventManager.isActive) {
            _this.emit("keydown", e);
            return e.catchEvent;
          }
          return e.catchEvent;
        });
        return $(this.attachment).keyup(function(e) {
          e.capture = function() {
            this.catchEvent = false;
            this.preventDefault();
            return this.stopImmediatePropagation();
          };
          if (_this.isActive && KeyEventManager.isActive) {
            _this.emit("keyup", e);
            return e.catchEvent;
          }
          return e.catchEvent;
        });
      };

      KeyEventManager.prototype.active = function() {
        return this.isActive = true;
      };

      KeyEventManager.prototype.deactive = function() {
        return this.isActive = false;
      };

      KeyEventManager.prototype.master = function() {
        if (KeyEventManager.current === this) {
          console.error("already mastered");
          console.trace();
          return;
        }
        this.active();
        if (KeyEventManager.current) {
          KeyEventManager.current.deactive();
          KeyEventManager.stack.push(KeyEventManager.current);
        }
        return KeyEventManager.current = this;
      };

      KeyEventManager.prototype.unmaster = function() {
        var prev;
        if (KeyEventManager.current !== this) {
          console.error("current input are not in master");
          console.trace();
          return;
        }
        this.deactive();
        prev = null;
        if (KeyEventManager.stack.length > 0) {
          prev = KeyEventManager.stack.pop();
          prev.active();
        }
        return KeyEventManager.current = prev;
      };

      return KeyEventManager;

    })(EventEmitter);
    Observable = (function(_super) {

      __extends(Observable, _super);

      function Observable() {
        Observable.__super__.constructor.call(this);
      }

      Observable.prototype.watch = function(property, callback) {};

      return Observable;

    })(EventEmitter);
    Util.clone = function(x) {
      var item, r, _i, _len;
      if (x === null || x === void 0) {
        return x;
      }
      if (typeof x.clone === "function") {
        return x.clone();
      }
      if (x.constructor === Array) {
        r = [];
        for (_i = 0, _len = x.length; _i < _len; _i++) {
          item = x[_i];
          r.push(Util.clone(item));
        }
        return r;
      }
      return x;
    };
    Util.compare = function(x, y) {
      var p, _i, _len;
      if (x === y) {
        return true;
      }
      for (p in y) {
        if (typeof x[p] === 'undefined') {
          return false;
        }
      }
      for (p in y) {
        if (y[p]) {
          switch (typeof y[p]) {
            case 'object':
              if (!Util.compare(y[p], x[p])) {
                return false;
              }
              break;
            case 'function':
              if (typeof x[p] === 'undefined' || (p !== 'equals' && y[p].toString() !== x[p].toString())) {
                return false;
              }
              break;
            default:
              if (y[p] !== x[p]) {
                return false;
              }
          }
        } else if (x[p]) {
          return false;
        }
      }
      for (_i = 0, _len = x.length; _i < _len; _i++) {
        p = x[_i];
        if (typeof y[p] === 'undefined') {
          return false;
        }
      }
      return true;
    };
    KeyEventManager.instances = [];
    KeyEventManager.stack = [];
    KeyEventManager.disable = function() {
      return this.isActive = true;
    };
    KeyEventManager.enable = function() {
      return this.isActive = false;
    };
    KeyEventManager.isActive = true;
    Key = {};
    Key["0"] = 48;
    Key["1"] = 49;
    Key["2"] = 50;
    Key["3"] = 51;
    Key["4"] = 52;
    Key["5"] = 53;
    Key["6"] = 54;
    Key["7"] = 55;
    Key["8"] = 56;
    Key["9"] = 57;
    Key.a = 65;
    Key.b = 66;
    Key.c = 67;
    Key.d = 68;
    Key.e = 69;
    Key.f = 70;
    Key.g = 71;
    Key.h = 72;
    Key.i = 73;
    Key.j = 74;
    Key.k = 75;
    Key.l = 76;
    Key.m = 77;
    Key.n = 78;
    Key.o = 79;
    Key.p = 80;
    Key.q = 81;
    Key.r = 82;
    Key.s = 83;
    Key.t = 84;
    Key.u = 85;
    Key.v = 86;
    Key.w = 87;
    Key.x = 88;
    Key.y = 89;
    Key.z = 90;
    Key.space = 32;
    Key.shift = 16;
    Key.ctrl = 17;
    Key.alt = 18;
    Key.left = 37;
    Key.up = 38;
    Key.right = 39;
    Key.down = 40;
    Key.enter = 13;
    Key.backspace = 8;
    Key.escape = 27;
    Key.del = Key["delete"] = 46;
    Key.esc = 27;
    Key.pageup = 33;
    Key.pagedown = 34;
    Key.tab = 9;
    Mouse = {};
    Mouse.left = 0;
    Mouse.middle = 1;
    Mouse.right = 2;
    Util.Key = Key;
    Leaf.Util = Util;
    Leaf.Key = Key;
    Leaf.Mouse = Mouse;
    Leaf.EventEmitter = EventEmitter;
    Leaf.Observable = Observable;
    return Leaf.KeyEventManager = KeyEventManager;
  })(this.Leaf);

}).call(this);
