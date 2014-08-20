// Generated by CoffeeScript 1.7.1
(function() {
  var CurrentTimeLabel, PageFooter, PageHeader, PageRoot,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  PageRoot = (function(_super) {
    __extends(PageRoot, _super);

    function PageRoot() {
      this.header = new PageHeader();
      this.footer = new PageFooter();
      PageRoot.__super__.constructor.call(this, pageRootTemplate);
    }

    return PageRoot;

  })(Leaf.Widget);

  PageHeader = (function(_super) {
    __extends(PageHeader, _super);

    function PageHeader() {
      PageHeader.__super__.constructor.call(this, headerTemplate);
    }

    PageHeader.prototype.setContent = function(text) {
      return this.node$.text("header:" + text);
    };

    return PageHeader;

  })(Leaf.Widget);

  PageFooter = (function(_super) {
    __extends(PageFooter, _super);

    function PageFooter() {
      PageFooter.__super__.constructor.call(this, footerTemplate);
    }

    PageFooter.prototype.setContent = function(text) {
      return this.node$.text("footer:" + text);
    };

    return PageFooter;

  })(Leaf.Widget);

  CurrentTimeLabel = (function(_super) {
    __extends(CurrentTimeLabel, _super);

    CurrentTimeLabel["public"] = true;

    function CurrentTimeLabel(template, option) {
      if (option == null) {
        option = {};
      }
      CurrentTimeLabel.__super__.constructor.call(this, template);
      this.expose("color");
      this.update();
      this.start();
    }

    CurrentTimeLabel.prototype.onSetColor = function(color) {
      this.color = color;
      return this.node$.css({
        color: color
      });
    };

    CurrentTimeLabel.prototype.start = function() {
      return this.timer = setInterval(this.update.bind(this), 100);
    };

    CurrentTimeLabel.prototype.update = function() {
      return this.node$.text(new Date());
    };

    CurrentTimeLabel.prototype.stop = function() {
      return clearTimeout(this.timer);
    };

    return CurrentTimeLabel;

  })(Leaf.Widget);

  Leaf.ns.register(PageRoot);

  Leaf.ns.register(PageFooter);

  Leaf.ns.register(PageHeader);

  Leaf.ns.register(CurrentTimeLabel);

  TEST.register(function() {
    var root;
    root = new PageRoot();
    root.appendTo(document.body);
    return root.UI.header$.css({
      backgroundColor: "blue"
    });
  });

}).call(this);
