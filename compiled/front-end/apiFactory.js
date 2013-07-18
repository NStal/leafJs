// Generated by CoffeeScript 1.6.2
(function() {
  var Leaf,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Leaf = window.Leaf;

  (function(Leaf) {
    var Api, ApiContext, ApiFactory, Request;

    ApiFactory = (function(_super) {
      __extends(ApiFactory, _super);

      function ApiFactory(apis) {
        this.apis = {};
        this.path = "api/";
        this.suffix = "";
        this.defaultMethod = "GET";
        this.acceptStatus = [200];
        this.infos = [];
      }

      ApiFactory.prototype.declare = function(name, params, option) {
        var info, method, url;

        if (option == null) {
          option = {};
        }
        console.assert(typeof name === "string");
        url = option.url || ("" + this.path + name + this.suffix);
        method = option.method || this.defaultMethod;
        params = params instanceof Array && params || [];
        info = {
          name: name,
          url: url,
          method: method,
          params: params
        };
        this.infos.push(info);
        return this;
      };

      ApiFactory.prototype.build = function() {
        var api, info, _i, _len, _ref;

        api = {};
        _ref = this.infos;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          info = _ref[_i];
          api[info.name] = new Api(info).toFunction();
        }
        return api;
      };

      return ApiFactory;

    })(Leaf.EventEmitter);
    Api = (function() {
      function Api(info) {
        this.info = info;
        this.declares = this.buildDeclares();
        this.method = this.info.method.toUpperCase();
        this.name = this.info.name;
        this.url = this.info.url;
      }

      Api.prototype.buildDeclares = function() {
        var declare, declares, param, paramInfo, paramName, shouldBe, _i, _len, _ref;

        declares = [];
        _ref = this.info.params;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          param = _ref[_i];
          paramInfo = param.split(":").filter(function(value) {
            return value;
          });
          paramName = paramInfo[0];
          shouldBe = paramInfo[1] || "string";
          declare = {
            name: paramName,
            optional: false
          };
          if (shouldBe.lastIndexOf("?") === (shouldBe.length - 1)) {
            declare.optional = true;
          }
          shouldBe = shouldBe.replace(/\?/g, "");
          if (shouldBe === "string") {
            declare.format = "string";
          } else if (shouldBe === "number") {
            declare.format = "number";
          } else if (shouldBe.length === 0) {
            declare.format = "string";
          } else {
            throw new Error("Unknow Format Declaration In API " + this.info.name + ":" + shouldBe);
          }
          declares.push(declare);
        }
        return declares;
      };

      Api.prototype.checkParam = function(value, declare) {
        var number;

        if (typeof value !== "number" && !value) {
          if (declare.optional) {
            return "";
          } else {
            throw new Error("API:" + this.info.name + "'s parameter:" + declare.name + " is required but given:" + value);
          }
        }
        if (typeof value === "number" && isNaN(value)) {
          throw new Error("API " + this.info.name + " parameter:" + declare.name + " recieve an NaN");
        }
        if (typeof value === declare.format) {
          return value;
        }
        if (typeof value === "number" && declare.format === "string") {
          console.warn("change param" + declare.name + " of API " + this.info.name + " from number to string");
          return value.toString();
        }
        if (typeof value === "string" && declare === "number") {
          number = parseFloat(value);
          if (isNaN(number)) {
            throw new Error("API " + this.info.name + " parameter:" + declare.name + " require an number but given an string");
          } else {
            console.warn("change param" + declare.name + " of API " + this.info.name + " from string to number");
            return value;
          }
        }
      };

      Api.prototype.checkParams = function(params) {
        var declare, index, _i, _j, _len, _len1, _ref, _ref1, _result;

        if (params.length === 1 && typeof params[0] === "object") {
          _ref = this.declares;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            declare = _ref[_i];
            params[declare.name] = encodeURIComponent(this.checkParam(params[declare.name], declare));
          }
          return params;
        } else {
          _result = {};
          _ref1 = this.declares;
          for (index = _j = 0, _len1 = _ref1.length; _j < _len1; index = ++_j) {
            declare = _ref1[index];
            _result[declare.name] = this.checkParam(params[index], declare);
          }
          return _result;
        }
      };

      Api.prototype.buildRequest = function(paramsDict) {
        var URI, body, key, query, queryArray, value, _ref;

        queryArray = [];
        for (key in paramsDict) {
          value = encodeURIComponent(paramsDict[key]);
          queryArray.push([key, value].join("="));
        }
        query = queryArray.join("&");
        URI = "";
        body = "";
        if ((_ref = this.method) === "GET" || _ref === "DELETE" || _ref === "PUT") {
          URI = "" + this.url + "?" + query;
        } else if (this.method === "POST") {
          URI = this.url;
          body = query;
        } else {
          console.warn("Unknow Method " + this.method + ",build as if it is GET");
        }
        return {
          URI: URI,
          body: body,
          context: new ApiContext(),
          method: this.method
        };
      };

      Api.prototype.invoke = function() {
        var params, requestInfo;

        params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        params = this.checkParams(params);
        requestInfo = this.buildRequest(params);
        return new Request(requestInfo).context;
      };

      Api.prototype.toFunction = function() {
        return this.invoke.bind(this);
      };

      return Api;

    })();
    Request = (function(_super) {
      __extends(Request, _super);

      function Request(info) {
        var xhr,
          _this = this;

        this.URI = info.URI;
        this.body = info.body;
        this.method = info.method;
        this.context = info.context;
        this.acceptStatus = [200, 302];
        this.xhr = new XMLHttpRequest();
        xhr = this.xhr;
        xhr.open(this.method, this.URI, true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.send(this.body);
        xhr.onreadystatechange = function(state) {
          var json, _ref;

          if (xhr.readyState !== 4) {
            return;
          }
          if (_ref = xhr.status, __indexOf.call(_this.acceptStatus, _ref) < 0) {
            _this.context._fail("Http Error", _this.createStatus());
            return;
          }
          if (xhr.getResponseHeader("content-type") === "text/json" || ApiFactory.forceJson) {
            json = _this.json();
            if (json) {
              if (json.state === true) {
                _this.context._success(json.data);
              } else if (json.state === false) {
                _this.context._fail(json.error, _this.createStatus());
              }
              return _this.context._response(json);
            } else {
              return _this.context._fail("Json Parse Error", _this.createStatus());
            }
          } else {
            _this.context._response(_this.text());
            return true;
          }
        };
      }

      Request.prototype.text = function() {
        return this.xhr.responseText;
      };

      Request.prototype.json = function() {
        var e, json;

        try {
          json = JSON.parse(this.xhr.responseText);
        } catch (_error) {
          e = _error;
          return null;
        }
        return json;
      };

      Request.prototype.createStatus = function() {
        return {
          httpCode: this.xhr.status,
          text: this.text(),
          json: this.json()
        };
      };

      return Request;

    })(Leaf.EventEmitter);
    ApiContext = (function() {
      function ApiContext() {
        this._response = function() {};
        this._fail = function() {};
        this._success = function() {};
        this._time = -1;
      }

      ApiContext.prototype.response = function(callback) {
        console.assert(typeof callback === "function");
        this._response = callback;
        return this;
      };

      ApiContext.prototype.fail = function(callback) {
        console.assert(typeof callback === "function");
        this._fail = callback;
        return this;
      };

      ApiContext.prototype.success = function(callback) {
        console.assert(typeof callback === "function");
        this._success = callback;
        return this;
      };

      ApiContext.prototype.timeout = function(time) {
        console.assert(typeof time === "number");
        this._time = time;
        return this;
      };

      return ApiContext;

    })();
    ApiFactory.forceJson = true;
    return Leaf.ApiFactory = ApiFactory;
  })(Leaf);

}).call(this);
