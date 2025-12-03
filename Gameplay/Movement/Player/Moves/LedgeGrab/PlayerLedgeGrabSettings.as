
class UPlayerLedgeGrabSettings : UHazeComposableSettings
{
	//Shimmy

	//are we allowed to shimmy sideways at all during a ledgegrab
	UPROPERTY()
	bool bShimmyAllowed = true;

	//
	UPROPERTY()
	float ShimmySpeedMin = 100.0;
	//
	UPROPERTY()
	float ShimmySpeedMax = 300.0;

	//ShimmyDash

	//
	UPROPERTY()
	float ShimmyDashAccelerationDuration = 0.0;

	//
	UPROPERTY()
	float ShimmyDashDuration = 0.36;
	//
	UPROPERTY()
	float ShimmyDashDistance = 200.0;

	//
	UPROPERTY()
	float ShimmyDashExitSpeed = 400;

	UPROPERTY()
	float CancelGravityStrength = 2075.0;

	// Maximum speed you can fall
	UPROPERTY()
	float CancelTerminalVelocity = 4000.0;

	// Settle height of the player on the ledge
	UPROPERTY()
	float SettleHeight = 120.0;

	UPROPERTY(Category = LedgeGrab | Hang)
	float LedgePitchMaximum = 10.0;

	UPROPERTY(Category = LedgeGrab | Hang)
	float LedgePitchMinimum = -10.0;

	// Start location of trace offset vertically from the players' root
	const float WallTraceVerticalOffset = 100.0;

	// How high we trace above the wanted ledge grab height
	const float TopTraceUpwardsReach = 60.0;
	// How low we trace above the wanted ledge grab height
	const float TopTraceDownwardsReach = 20.0;
	// How deep the ledge needs to be to be grabbable
	const float TopTraceDepth = 8.0;
}