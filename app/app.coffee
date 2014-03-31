# Calculate the hours for each team member this results in a chart like
#
# A:      0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
# B:     20 21 22 23  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
# C:     17 18 19 20 21 22 23  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
#                                   ^^          ^^             ^^
#                                   Day start   Local time     Day end
#
# The process for calculating these graphs works like this:
# 1. The team members are sorted low to high by dstOffset + rawOffset
# 2. The hours for the first member in the sorted list are simply 0 to 23
# 3. The remaining team members start their hours according to their
#    dstOffset + rawOffset.
class TeamTimezoneWidget
    constructor: (@config) ->
        # Ready will become true once data fetching has completed. The ready
        # state is useful to avoid rendering before data is present.
        @ready = false

        @run(false)

        # The local timezone offset in milliseconds. Note we negate the result
        # to ensure UTC-8 translates to -14400000.
        @fetch_data(@config.url)

    run: (animated) ->
        @local_ts = Date.now()
        @utc_ts = new Date().getTime()
        @local_timezone_offset = -1 * (new Date().getTimezoneOffset()) * 60 * 1000

        if @ready
            @calculate_hours()
            @render(animated)

        # Redraw every 30 seconds
        callback = => @run(true)
        setTimeout(callback, 30 * 1000)

    fetch_data: (url) ->
        $.ajax
            method: "GET"
            url: url
            success: (data) =>
                @team = data.team
                @display_widget()
            error: (xhr, status, error) =>
                throw "TeamTimezoneWidget: Could not fetch data, sorry."

    display_widget: ->
        promises = []

        for member in @team
            promises.push(@fetch_member_timezone(member))

        $.when.apply($, promises).done(=>
            @ready = true

            for result, i in arguments
                @update_member_timezone(@team[i], result[0])

            @sort_team_by_timezone_offset()
            @calculate_hours()
            @render()
        )

    fetch_member_timezone: (member) ->
        timestamp = Math.round(@local_ts / 1000)

        return $.ajax
            method: "GET"
            url: "https://maps.googleapis.com/maps/api/timezone/json?location=#{member.location}&timestamp=#{timestamp}&sensor=false&key=#{@config.api_key}"

    update_member_timezone: (member, data) ->
        if data? and data.status? and data.status == 'OK'
            # Convert to milliseconds
            data.dstOffset *= 1000
            data.rawOffset *= 1000

            member.timezone = data
            member.timezone_offset = data.dstOffset + data.rawOffset
        else
            # TODO: Log this error!
            member.timezone = false

    sort_team_by_timezone_offset: ->
        @team = _.sortBy(@team, 'timezone_offset')

    calculate_hours: ->
        for member, i in @team
            member.hours = []

            start = Math.floor(member.timezone_offset / 60 / 60 / 1000)
            current_hour = @utc_hour_offset_by(member.timezone_offset)
            current_minute = @utc_minute_offset_by(member.timezone_offset)

            for i in [0...23]
                raw_hour = i + start
                hour = raw_hour % 24

                if hour < 0
                    hour = 24 + hour

                if hour == 0
                    label = @utc_short_date_offset_by(member.timezone_offset + (raw_hour - current_hour) * 60 * 60 * 1000)
                else
                    label = hour

                member.hours.push
                    label: label
                    hour: hour
                    minute: if hour == current_hour then current_minute else 0
                    # TODO: Proper business hours.
                    is_business_hours: hour >= 9 and hour <= 17
                    is_current: hour == current_hour

    utc_ts_offset_by: (offset) ->
        d = new Date
        d.setTime(@utc_ts + offset)
        return d

    utc_hour_offset_by: (offset) ->
        d = @utc_ts_offset_by(offset)
        return d.getUTCHours()

    utc_minute_offset_by: (offset) ->
        d = @utc_ts_offset_by(offset)
        return d.getUTCMinutes()

    utc_short_date_offset_by: (offset) ->
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        d = @utc_ts_offset_by(offset)
        return "#{months[d.getUTCMonth()]} #{d.getUTCDate()}"

    render: (animated) ->
        $(@config.el).html(@config.templates.widget(@));

        if animated
            effect = 'flash'
            $(@config.el)
                .addClass("animated #{effect}")
                .one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend",
                     -> $(@).removeClass("animated #{effect}"))

window.TeamTimezoneWidget = TeamTimezoneWidget
