class USummitSplineFollowSettings : UHazeComposableSettings
{
	// The distance it travels per second along the spline
	UPROPERTY()
	float MoveSpeed = 350.0;

	// If it should start going back along the spline after moving to the end
	UPROPERTY()
	bool bShouldPingPong = true;

	// The delay it waits before it starts going the other way after reaching the end
	UPROPERTY()
	float EndDelay = 0.25; 
}