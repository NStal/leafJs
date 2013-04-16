// Generated by CoffeeScript 1.4.0
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  (function(Leaf) {
    var TemplateManager;
    TemplateManager = (function(_super) {

      __extends(TemplateManager, _super);

      function TemplateManager() {
        TemplateManager.__super__.constructor.call(this);
        this.tids = [];
        this.baseUrl = "template/";
        this.templates = {};
        this.suffix = ".html";
        this.timeout = 10000;
      }

      TemplateManager.prototype.use = function() {
        var tids;
        tids = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return this.tids.push.apply(this.tids, tids);
      };

      TemplateManager.prototype.start = function() {
        var all, remain, remainTemplates, tid, _i, _j, _len, _len1, _ref,
          _this = this;
        all = this._fromDomAll();
        _ref = this.tids;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tid = _ref[_i];
          this.templates[tid] = all[tid];
        }
        if (this._isRequirementComplete()) {
          this._ready();
          return this;
        }
        remain = this._getNotCompleteRequirements();
        remainTemplates = this._fromDomForEach(remain);
        for (_j = 0, _len1 = remain.length; _j < _len1; _j++) {
          tid = remain[_j];
          this.templates[tid] = remainTemplates[tid];
        }
        if (this._isRequirementComplete()) {
          this._ready();
          return this;
        }
        remain = this._getNotCompleteRequirements();
        return this._fromXHRForEach(remain, function(err, tid, template) {
          if (err != null) {
            _this.emit("error", err);
            return;
          }
          _this.templates[tid] = template;
          if (_this._isRequirementComplete()) {
            return _this._ready();
          }
        });
      };

      TemplateManager.prototype._ready = function() {
        return this.emit("ready", this.templates);
      };

      TemplateManager.prototype._getNotCompleteRequirements = function() {
        var tid, _i, _len, _ref, _results;
        _ref = this.tids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tid = _ref[_i];
          if (!this.templates[tid]) {
            _results.push(tid);
          }
        }
        return _results;
      };

      TemplateManager.prototype._isRequirementComplete = function() {
        var tid, _i, _len, _ref;
        _ref = this.tids;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tid = _ref[_i];
          if (!this.templates[tid]) {
            return false;
          }
        }
        return true;
      };

      TemplateManager.prototype._fromDomAll = function() {
        try {
          return JSON.parse(document.getElementById("leaf-templates").innerHTML);
        } catch (e) {
          return {};
        }
      };

      TemplateManager.prototype._fromDomForEach = function(tids) {
        var templateNode, templates, tid, _i, _len;
        templates = {};
        for (_i = 0, _len = tids.length; _i < _len; _i++) {
          tid = tids[_i];
          templateNode = document.getElementById("leaf-templates-" + tid);
          templates[tid] = templateNode ? templateNode.innerHTML : void 0;
        }
        return templates;
      };

      TemplateManager.prototype._fromXHRForEach = function(tids, callback) {
        var targetURI, tid, _fn, _i, _len,
          _this = this;
        _fn = function() {
          var XHR;
          XHR = new XMLHttpRequest();
          XHR.open("GET", targetURI, true);
          XHR.send(null);
          XHR.tid = tid;
          XHR.terminator = setTimeout(function() {
            callback("timeout", XHR.tid, null);
            XHR.done = true;
            return XHR.abort();
          }, _this.timeout);
          return XHR.onreadystatechange = function() {
            var _ref;
            if (this.done) {
              return;
            }
            if (this.readyState === 4) {
              this.done = true;
              if ((_ref = this.status) === 200 || _ref === 302 || _ref === 304) {
                return callback(null, this.tid, this.responseText);
              } else {
                return callback(this.status, this.tid, null);
              }
            }
          };
        };
        for (_i = 0, _len = tids.length; _i < _len; _i++) {
          tid = tids[_i];
          if (tid.indexOf(".") >= 1) {
            targetURI = this.baseUrl + tid;
          } else {
            targetURI = this.baseUrl + tid + this.suffix;
          }
          _fn();
        }
        return null;
      };

      return TemplateManager;

    })(Leaf.EventEmitter);
    return Leaf.TemplateManager = TemplateManager;
  })(this.Leaf);

}).call(this);
