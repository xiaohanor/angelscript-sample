class UPlayerLedgeMantleSettings : UHazeComposableSettings
{
	/**** General Mantle Settings ****/

	const float InputToWallAngleCutoff = 60;

	//Max Angle to face towards wall to trigger
	const float EnterAngleCutoff = 45;
	
	//How far into the ledge do we trace for top impact
	const float TopTraceDepth = 30;

	//
	UPROPERTY()
	float WallPitchMinimum = -10;
	UPROPERTY()
	float WallPitchMaximum = 10;
	
	UPROPERTY()
	float TopPitchMaximum = 10;
	UPROPERTY()
	float TopPitchMinimum = -10;

	UPROPERTY()
	bool bIgnoreCollisionCheckForEnter = false;
	
	/**** Grounded Mantle settings ****/

	//Lowest Mantle we can perform
	const float LowMantleMin = 80;
	
	//Max height for a low mantle
	const float LowMantleCutoff = 150;
	
	//Max height for a high mantle
	const float HighMantleMax = 250;
	
	//Max distance away from the wall we can trigger
	const float EnterDistanceMax = 250;

	//Duration for low enter from shortest distance (this may need to change to accomodate for standstill climb up)
	const float Low_EnterDurationMin = 0.1;
	//Duration for low enter from longest distance
	const float Low_EnterDurationMax = 0.3;

	//Duration for high enter from shortest distance
	const float High_EnterDurationMin = 0.1;
	//Duration for high enter from longest distance
	const float High_EnterDurationMax = 0.3;
	
	const float StandStillExitDuration = 0.5;

	const float ExitDuration = 0.3;

	const float ExitDistance = 150;

	/**** Airborne Mantle Settings ****/

	//How far forward we trace for initial wall hit
	const float AirborneMantleAnticipationTime = 0.1;

	const float AirborneAngleCutoff = 75;

	const float AirborneMantleForwardTraceDistance = 125;

	//Only mantle if its within this vertical reach
	float AirborneMantleMaxTopDistance = 160;
	
	const float AirborneTopTraceHeight = 240;

	/**** Airborne Roll Settings ****/

	//Perform roll if vertical delta is lower then this value
	const float AirborneRollMantleVerticalCutOff = 60;

	//Time to bring us up onto the ledge
	const float AirborneRollMantleEnterDuration = 0.135;

	//Time to bring us to the exit location
	const float AirborneRollMantleExitDuration = 0.1;
	
	//How far into the ledge do we travel
	const float AirborneRollMantleExitDistance = 75;

	/**** Airborne Low Settings ****/

	const float AirborneLowMantleEnterDuration = 0.1;

	const float AirborneLowMantleExitDuration = 0.6;

	const float AirborneLowMantleExitDistance = 80;

	//How much clearance do we need below the lowest capsule point on enter
	const float AirborneLowMinimumHeight = 60;

	/**** Falling Low Mantle Settings ****/

	const float FallingLowMantleMaxTopDistance = 200;

	const float FallingLowMantleTopTraceHeight = 240;

	const float FallingLowMantleWallOffset = 56;

	const float FallingLowExitDistance = 80;

	const float FallingLowMinimumHeight = 80;

	//Time to travel to full capsule height below ledge
	const float FallingLowMantleEnterDuration = 0.1;

	//Time to climb up onto the ledge
	const float FallingLowMantleClimbDuration = 0.9;

	/**** Jump Climb Mantle ****/

	const float JumpClimbMantleMaxTopDistance = 200;

	const float JumpClimbMantleTopTraceHeight = 240;

	const float JumpClimbMantleEnterDuration = 0.1;

	const float JumpClimbMantleClimbDuration = 0.5;

	const float JumpClimbMantleWallOffset = 56;

	const float JumpClimbMantleExitDistance = 80;

	const float JumpClimbMantleMinimumHeight = 20;

	/**** Scramble Mantle Settings ****/

	const float ScrambleTopTraceHeight = 220;

	const float ScrambleEnterDuration = 0.4;

	//This is the capability duration in which you are locked from other actions, animation will play for longer and allow blend outs
	const float ScrambleExitDuration = 0.2;
}