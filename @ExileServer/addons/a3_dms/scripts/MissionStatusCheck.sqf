/*
	DMS_MissionStatusCheck

	Created by eraser1

	Each mission has its own index in "DMS_Mission_Arr".
	Every index is a subarray with the values:
	[
		_position,
		_completionInfo,
		[_timeStarted,_timeUntilFail],
		[_AIUnit1,_AIUnit2,...,_AIUnitX],
		[
			[_cleanupObj1,_cleanupObj2,...,_cleanupObjX],
			[_crate,_vehicle1,_vehicle2,...,_vehicleX],
			[_crate_loot_values]
		],
		[_msgWIN,_msgLose],
		_markers
	]
*/
if (DMS_Mission_Arr isEqualTo []) exitWith
{
	if (DMS_DEBUG) then
	{
		diag_log "DMS_DEBUG MissionStatusCheck :: DMS_Mission_Arr is empty!";
	};
};


_index = 0;
{
	call
	{
		if (DMS_DEBUG) then
		{
			diag_log format ["DMS_DEBUG MissionStatusCheck :: Checking Mission Status (index %1): %2",_index,_x];
		};
		_position					= _x select 0;
		_success					= (_x select 1) call DMS_MissionSuccessState;
		_timeStarted				= _x select 2 select 0;
		_timeUntilFail				= _x select 2 select 1;
		_units						= _x select 3;
		_buildings					= _x select 4 select 0;
		_loot						= _x select 4 select 1;
		_crate_loot_values			= _x select 4 select 2;
		_msgWIN						= _x select 5 select 0;
		_msgLose					= _x select 5 select 1;
		_markers 					= _x select 6;

		if (_success) exitWith
		{
			//Use FSM instead
			//[DMS_CompletedMissionCleanupTime,DMS_CleanUp,(_units+_buildings),false] call ExileServer_system_thread_addTask;
			_arr = DMS_Mission_Arr deleteAt _index;

			[_loot select 0,_crate_loot_values] call DMS_FillCrate;
			_msgWIN call DMS_BroadcastMissionStatus;
			[_markers,"win"] call DMS_RemoveMarkers;

			if (DMS_DEBUG) then
			{
				diag_log format ["DMS_DEBUG MissionStatusCheck :: Mission Success at %1 with message %2.",_position,_msgWIN];
			};
		};

		if (DMS_MissionTimeoutReset && {[_position,DMS_MissionTimeoutResetRange] call ExileServer_util_position_isPlayerNearby}) exitWith
		{
			_x set [2,[diag_tickTime,_timeUntilFail]];

			if (DMS_DEBUG) then
			{
				diag_log format ["DMS_DEBUG MissionStatusCheck :: Mission Timeout Extended at %1 with timeout after %2 seconds. Position: %3",diag_tickTime,_timeUntilFail,_position];
			};
		};

		if ((diag_tickTime-_timeStarted)>_timeUntilFail) exitWith
		{
			(_units+_buildings+_loot) call DMS_CleanUp;
			_arr = DMS_Mission_Arr deleteAt _index;

			_msgLose call DMS_BroadcastMissionStatus;
			[_markers,"lose"] call DMS_RemoveMarkers;

			if (DMS_DEBUG) then
			{
				diag_log format ["DMS_DEBUG MissionStatusCheck :: Mission Fail at %1 with message %2.",_position,_msgLose];
			};
		};
	};
	_index = _index + 1;
	false;
} count DMS_Mission_Arr;