class UTeenDragonLedgeDownSettings : UHazeComposableSettings
{
	// DOWN
	UPROPERTY(Category = "Ledge Down")
	float LedgeDownDuration = 0.53;

	UPROPERTY(Category = "Ledge Down")
	float LedgeDownTurnDuration = 0.2;

	// How far forward we check if there is a ledge in front of you
	UPROPERTY(Category = "Ledge Down")
	float LedgeDownGroundTraceForwardOffset = 100.0;

	// How far forward we check if there is a ground after ledge in front of you
	UPROPERTY(Category = "Ledge Down")
	float DownGroundTraceForwardOffset = 350.0;

	UPROPERTY(Category = "Ledge Down")
	float DownGroundTraceMaxDownDistance = 600.0;

	UPROPERTY(Category = "Ledge Down")
	float DownGroundTraceMinDownDistance = 300.0;

	// FALL
	UPROPERTY(Category = "Ledge Fall")
	float LedgeFallMaxDuration = 0.2;

	UPROPERTY(Category = "Ledge Fall")
	FHazeRange FallGroundTraceForwardOffset = FHazeRange(210, 125); 

	UPROPERTY(Category = "Ledge Fall")
	float FallTargetLocationForwardOffset = 50.0;

	UPROPERTY(Category = "Ledge Fall")
	float FallTargetLocationDownOffset = 200.0;

	UPROPERTY(Category = "Ledge Fall")
	FHazeRange FallSpeedTowardLedgeForForwardOffset = FHazeRange(0.0, 700);
}