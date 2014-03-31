(function() {
  var TeamTimezoneWidget;

  TeamTimezoneWidget = (function() {
    function TeamTimezoneWidget(config) {
      this.config = config;
      this.ready = false;
      this.run(false);
      this.fetch_data(this.config.url);
    }

    TeamTimezoneWidget.prototype.run = function(animated) {
      var callback;
      this.local_ts = Date.now();
      this.utc_ts = new Date().getTime();
      this.local_timezone_offset = -1 * (new Date().getTimezoneOffset()) * 60 * 1000;
      if (this.ready) {
        this.calculate_hours();
        this.render(animated);
      }
      callback = (function(_this) {
        return function() {
          return _this.run(true);
        };
      })(this);
      return setTimeout(callback, 30 * 1000);
    };

    TeamTimezoneWidget.prototype.fetch_data = function(url) {
      return $.ajax({
        method: "GET",
        url: url,
        success: (function(_this) {
          return function(data) {
            _this.team = data.team;
            return _this.display_widget();
          };
        })(this),
        error: (function(_this) {
          return function(xhr, status, error) {
            throw "TeamTimezoneWidget: Could not fetch data, sorry.";
          };
        })(this)
      });
    };

    TeamTimezoneWidget.prototype.display_widget = function() {
      var member, promises, _i, _len, _ref;
      promises = [];
      _ref = this.team;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        member = _ref[_i];
        promises.push(this.fetch_member_timezone(member));
      }
      return $.when.apply($, promises).done((function(_this) {
        return function() {
          var i, result, _j, _len1;
          _this.ready = true;
          for (i = _j = 0, _len1 = arguments.length; _j < _len1; i = ++_j) {
            result = arguments[i];
            _this.update_member_timezone(_this.team[i], result[0]);
          }
          _this.sort_team_by_timezone_offset();
          _this.calculate_hours();
          return _this.render();
        };
      })(this));
    };

    TeamTimezoneWidget.prototype.fetch_member_timezone = function(member) {
      var timestamp;
      timestamp = Math.round(this.local_ts / 1000);
      return $.ajax({
        method: "GET",
        url: "https://maps.googleapis.com/maps/api/timezone/json?location=" + member.location + "&timestamp=" + timestamp + "&sensor=false&key=" + this.config.api_key
      });
    };

    TeamTimezoneWidget.prototype.update_member_timezone = function(member, data) {
      if ((data != null) && (data.status != null) && data.status === 'OK') {
        data.dstOffset *= 1000;
        data.rawOffset *= 1000;
        member.timezone = data;
        return member.timezone_offset = data.dstOffset + data.rawOffset;
      } else {
        return member.timezone = false;
      }
    };

    TeamTimezoneWidget.prototype.sort_team_by_timezone_offset = function() {
      return this.team = _.sortBy(this.team, 'timezone_offset');
    };

    TeamTimezoneWidget.prototype.calculate_hours = function() {
      var current_hour, current_minute, hour, i, label, member, raw_hour, start, _i, _len, _ref, _results;
      _ref = this.team;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        member = _ref[i];
        member.hours = [];
        start = Math.floor(member.timezone_offset / 60 / 60 / 1000);
        current_hour = this.utc_hour_offset_by(member.timezone_offset);
        current_minute = this.utc_minute_offset_by(member.timezone_offset);
        _results.push((function() {
          var _j, _results1;
          _results1 = [];
          for (i = _j = 0; _j < 23; i = ++_j) {
            raw_hour = i + start;
            hour = raw_hour % 24;
            if (hour < 0) {
              hour = 24 + hour;
            }
            if (hour === 0) {
              label = this.utc_short_date_offset_by(member.timezone_offset + (raw_hour - current_hour) * 60 * 60 * 1000);
            } else {
              label = hour;
            }
            _results1.push(member.hours.push({
              label: label,
              hour: hour,
              minute: hour === current_hour ? current_minute : 0,
              is_business_hours: hour >= 9 && hour <= 17,
              is_current: hour === current_hour
            }));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    TeamTimezoneWidget.prototype.utc_ts_offset_by = function(offset) {
      var d;
      d = new Date;
      d.setTime(this.utc_ts + offset);
      return d;
    };

    TeamTimezoneWidget.prototype.utc_hour_offset_by = function(offset) {
      var d;
      d = this.utc_ts_offset_by(offset);
      return d.getUTCHours();
    };

    TeamTimezoneWidget.prototype.utc_minute_offset_by = function(offset) {
      var d;
      d = this.utc_ts_offset_by(offset);
      return d.getUTCMinutes();
    };

    TeamTimezoneWidget.prototype.utc_short_date_offset_by = function(offset) {
      var d, months;
      months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      d = this.utc_ts_offset_by(offset);
      return "" + months[d.getUTCMonth()] + " " + (d.getUTCDate());
    };

    TeamTimezoneWidget.prototype.render = function(animated) {
      var effect;
      $(this.config.el).html(this.config.templates.widget(this));
      if (animated) {
        effect = 'flash';
        return $(this.config.el).addClass("animated " + effect).one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
          return $(this).removeClass("animated " + effect);
        });
      }
    };

    return TeamTimezoneWidget;

  })();

  window.TeamTimezoneWidget = TeamTimezoneWidget;

}).call(this);
