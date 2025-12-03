class UPlayerSlideDashSettings : UHazeComposableSettings
{
	// Time it takes to slowdown before doing the dash
	UPROPERTY()
	float SlowdownTime = 0.2;
	
	// Horizontal speed to slow down to before doing the dash
	UPROPERTY()
	float SlowdownSpeed = 600.0;


	// Total duration of the dash
	UPROPERTY()
	float DashDuration = 0.5;

	// The start speed of the dash. Higher values increases the length and explosiveness of the dash
	UPROPERTY()
	float EnterSpeed = 1450.0;
	
	// How much you can rotate during the dash
	UPROPERTY()
	float TurnRate = 6.0;
}