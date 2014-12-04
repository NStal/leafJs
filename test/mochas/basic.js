// Generated by CoffeeScript 1.8.0
(function() {
  var Util;

  describe("test basic", function() {
    return it("should have window.Leaf exported", function(done) {
      if (!window.Leaf) {
        throw new Error("window.Leaf not exported");
      }
      return done();
    });
  });

  describe("test event emitter", function() {
    it("test basic bind", function(done) {
      var et;
      et = new Leaf.EventEmitter();
      et.on("event", function(param, param2) {
        if (param !== "foo" || param2 !== "bar") {
          throw new Error("should be able to emit params correctly");
        }
        return done();
      });
      return et.emit("event", "foo", "bar");
    });
    it("test alias addListener", function(done) {
      var et;
      et = new Leaf.EventEmitter();
      et.addListener("event", function(param, param2) {
        if (param !== "foo" || param2 !== "bar") {
          throw new Error("should be able to emit params correctly");
        }
        return done();
      });
      return et.emit("event", "foo", "bar");
    });
    it("test once", function(done) {
      var et;
      et = new Leaf.EventEmitter();
      et.once("event", function(param, param2) {
        if (et._events.event.length > 0) {
          console.debug(et._events);
          throw new Error("once don't remove listener at callback");
        }
        return done();
      });
      return et.emit("event");
    });
    it("test remove listener", function(done) {
      var et, reachHere;
      et = new Leaf.EventEmitter();
      reachHere = false;
      et.on("event", function() {
        return reachHere = true;
      });
      et.removeListener("event");
      et.emit("event");
      if (!reachHere) {
        throw new Error("removeListener without a second parameter provide should have no effect");
      }
      et.on("event2", function() {
        return false;
      });
      et.removeAllListeners("event2");
      if (!et._events.event || et._events.event.length !== 1) {
        throw new Error("removeAllListener with a event name provided should't effect other event's listeners ");
      }
      if (et._events.event2 && et._events.event2.length !== 0) {
        throw new Error("removeAllListener with a event name provided and matches should have effect");
      }
      et.on("event", function() {
        return true;
      });
      et.removeAllListeners();
      if (et._events.event && et._events.event.length > 0 || et._events.event2 && et._events.event2.length > 0) {
        console.log(et._events);
        throw new Error("removeAllListener without a event name should remove all listeners");
      }
      return done();
    });
    it("bubble should work", function(done) {
      var child, parent;
      parent = new Leaf.EventEmitter();
      child = new Leaf.EventEmitter();
      parent.bubble(child, "click");
      parent.on("click", function(event) {
        if (!event || event.type !== "click") {
          throw new Error("bubble wrong data");
        }
        return done();
      });
      return child.emit("click", {
        type: "click"
      });
    });
    it("stopBubble should work", function(done) {
      var child, parent, reachHere;
      parent = new Leaf.EventEmitter();
      child = new Leaf.EventEmitter();
      parent.bubble(child, "click");
      parent.on("click", function(event) {
        throw new Error("stop bubble should work!");
      });
      parent.stopBubble(child);
      child.emit("click", {
        type: "click"
      });
      parent.removeAllListeners();
      parent.bubble(child, "click");
      reachHere = false;
      parent.on("click", function(data) {
        return reachHere = true;
      });
      parent.stopBubble(child, "notClick");
      child.emit("click");
      if (!reachHere) {
        throw new Error("stopBubble with another event shouldn't have effect");
      }
      reachHere = false;
      parent.stopBubble(child, "click");
      child.emit("click", {
        type: "click"
      });
      if (reachHere) {
        throw new Error("stopBubble with correct child and event should have effect");
      }
      return done();
    });
    it("stopAllBubbles should work", function(done) {
      var child, parent;
      parent = new Leaf.EventEmitter();
      child = new Leaf.EventEmitter();
      parent.bubble(child, "click");
      parent.on("click", function(event) {
        throw new Error("stop bubble should work!");
      });
      parent.stopAllBubbles();
      child.emit("click", {
        type: "click"
      });
      if (parent._bubbles.length > 0) {
        throw new Error("stopAllBubbles should remove all bubbles");
      }
      return done();
    });
    it("test listenBy", function(done) {
      var child, parent;
      parent = {
        name: "parent",
        onClick: function(event) {
          if (this.name !== "parent") {
            throw new Error("invalid context set");
          }
          return this.hasClick = true;
        },
        onTouch: function(event) {
          if (this.name !== "parent") {
            throw new Error("invalid context set");
          }
          return this.hasTouch = true;
        }
      };
      child = new Leaf.EventEmitter;
      child.listenBy(parent, "onClick", parent.onClick);
      child.listenBy(parent, "onTouch", parent.onTouch);
      if (child._events.onClick.length !== 1 || child._events.onTouch.length !== 1) {
        throw new Error("listenBy should set _events");
      }
      child.emit("onClick");
      child.emit("onTouch");
      if (!parent.hasClick || !parent.hasTouch) {
        throw new Error("listenBy should trigger event listeners with the contexdt");
      }
      child.stopListenBy(parent);
      if (child._events.onClick && child._events.onClick.length !== 0 || child._events.onTouch && child._events.onTouch.length !== 0) {
        throw new Error("stopListenBy should remove all the listen by");
      }
      return done();
    });
    return it("test mixin", function(done) {
      var obj;
      obj = {
        _events: {
          value: 5
        }
      };
      Leaf.EventEmitter.mixin(obj);
      if (!obj._events || !obj.on) {
        throw new Error("mixin not working");
      }
      if (obj._events.value === 5) {
        throw new Error("mixin should overwrite _events any way.");
      }
      return done();
    });
  });

  Util = Leaf.Util;

  describe("Util tests", function() {
    it("HTML related", function(done) {
      var Div, TextNode;
      TextNode = document.createTextNode("abc");
      Div = document.createElement("div");
      if (Util.isHTMLElement(TextNode)) {
        throw new Error("TextNode isnt html element");
      }
      if (!Util.isHTMLElement(Div)) {
        throw new Error("Div is html element");
      }
      if (!Util.isHTMLNode(TextNode)) {
        throw new Error("TextNode is html node");
      }
      if (!Util.isHTMLNode(Div)) {
        throw new Error("Div is html node");
      }
      return done();
    });
    it("is mobile", function(done) {
      return done();
    });
    it("string manipulation", function(done) {
      var camel, cameledSlug, capitalCamel, slug, slugedCamel;
      camel = "camelCaseIsCodeFriendly";
      slug = "slug-is-readable";
      capitalCamel = Util.capitalize(camel);
      if (camel[0].toUpperCase() !== capitalCamel[0] || camel.substring(1) !== capitalCamel.substring(1)) {
        throw new Error("capitalize failure");
      }
      slugedCamel = Util.camelToSlug(camel);
      if (slugedCamel !== "camel-case-is-code-friendly") {
        throw new Error("invalid camelToSlug");
      }
      cameledSlug = Util.slugToCamel(slug);
      if (cameledSlug !== "slugIsReadable") {
        throw new Error("invalid slugToCamel");
      }
      return done();
    });
    it("clone", function(done) {
      var a, b, result;
      a = {
        array: [
          {
            value: 0
          }
        ],
        foo: null,
        bar: {
          zero: 0,
          string: "abc",
          foo: null
        }
      };
      b = Util.clone(a);
      result = true;
      result && (result = b.array[0].value === 0);
      result && (result = b.array !== a.array);
      result && (result = b.foo === null);
      result && (result = b.bar.zero === 0);
      result && (result = b.bar !== a.bar);
      result && (result = b.bar.string === "abc");
      result && (result = b.bar.foo === null);
      if (!result) {
        throw new Error("clone failed");
      }
      return done();
    });
    return it("compare", function(done) {
      var a, b;
      a = {
        array: [
          {
            value: 0
          }
        ],
        foo: null,
        bar: {
          zero: 0,
          string: "abc",
          foo: null
        }
      };
      b = Util.clone(a);
      if (!Util.compare(a, b)) {
        throw new Error("invalid compare");
      }
      b.array[0].value = 1;
      if (Util.compare(a, b)) {
        throw new Error("fail to compare value in deep array");
      }
      return done();
    });
  });

  describe("error doc", function() {
    return it("test Error doc", function(done) {
      var Errors, invalidParameter, ioError, networkError, nto;
      Errors = Leaf.ErrorDoc.create().define("IOError").define("LogicError").define("NetworkError", "IOError").define("InvalidParameter", "LogicError", {
        message: "You are so stupid to provide a valid parameters I guess",
        code: 5
      }).define("NetworkTimeout", "NetworkError").generate();
      ioError = new Errors.IOError("message");
      invalidParameter = new Errors.InvalidParameter(null, {
        code: 10
      });
      nto = new Errors.NetworkTimeout();
      if (ioError.message !== "message") {
        throw new Error("bad message set");
      }
      networkError = new Errors.NetworkError("message", {
        via: {
          name: "hehe"
        }
      });
      if (networkError.via.name !== "hehe") {
        throw new Error("invalid meta set");
      }
      if (!(networkError instanceof Errors.IOError)) {
        throw new Error("fail to inherit errors");
      }
      if (invalidParameter instanceof Errors.IOError) {
        throw new Error("invalid parameter should be logic error");
      }
      if (invalidParameter.message !== "You are so stupid to provide a valid parameters I guess") {
        throw new Error("predefined meta no take effect");
      }
      if (invalidParameter.code !== 10) {
        console.debug(invalidParameter);
        throw new Error("fail to overwrite predefined error props");
      }
      if (!(nto instanceof Errors.IOError)) {
        throw new Error("inherit twice not working");
      }
      return done();
    });
  });

}).call(this);
