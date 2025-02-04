SUBSYSTEM_DEF(time_track)
	name = "Time Tracking"
	wait = 1 SECONDS
	subsystem_flags = SS_NO_INIT|SS_NO_TICK_CHECK
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

	var/last_measurement = 0
	var/measurement_delay = 60

	var/stat_time_text
	var/time_dilation_text

/datum/controller/subsystem/time_track/fire()
	if(++last_measurement == measurement_delay)
		last_measurement = 0
		var/current_realtime = REALTIMEOFDAY
		var/current_byondtime = world.time
		var/current_tickcount = world.time/world.tick_lag

		if (!first_run)
			var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))

			time_dilation_current = tick_drift / (current_tickcount - last_tick_tickcount) * 100

			time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
			time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
			time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
		else
			first_run = FALSE
		last_tick_realtime = current_realtime
		last_tick_byond_time = current_byondtime
		last_tick_tickcount = current_tickcount
		//SSblackbox.record_feedback("associative", "time_dilation_current", 1, list("[SQLtime()]" = list("current" = "[time_dilation_current]", "avg_fast" = "[time_dilation_avg_fast]", "avg" = "[time_dilation_avg]", "avg_slow" = "[time_dilation_avg_slow]")))
		time_dilation_text = "[round(time_dilation_current,1)]% AVG:([round(time_dilation_avg_fast,1)]%, [round(time_dilation_avg,1)]%, [round(time_dilation_avg_slow,1)]%)"

	//stat_time_text = "Server Time: [time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")]\n\nRound Time: [WORLDTIME2TEXT("hh:mm:ss")]\n\nStation Time: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]\n\n[time_dilation_text]"
	stat_time_text = time_dilation_text
