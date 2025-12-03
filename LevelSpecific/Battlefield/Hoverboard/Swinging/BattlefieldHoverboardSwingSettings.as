class UBattlefieldHoverboardSwingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = SwingSettings)
	float GravityAcceleration = 500.0;

	UPROPERTY(Category = SwingSettings)
	float InputAcceleration = 1200.0;

	// If our speed in the swing exceeds this, apply the extra overspeed drag
	// UPROPERTY(Category = SwingSettings)
	// float MaximumSwingVelocityBeforeOverspeedDrag = 10000.0;

	/*
		Exposed to the swing point
	*/
	UPROPERTY(Category = SwingPointSettings)
	float TetherLength = 800.0;

	// How much speed giving full input gives us, Speed is calculated as a factor of Tether length / BaseRopeLength in swing movement
	const float InputSpeed = 1000;

	// Baseline rope length calculated for to give full speed
	const float RopeLength = 800;

	//Drag used to align the players velocity with the swing direction
	// const float HorizontalDragCoefficient = 0.3;

	//Drag affecting our aligned forward swing
	// const float VerticalDragCoefficient = 0.6;

	//Drag affecting the player when no input is given
	const float DragCoefficient = 1.25;

	// Additional drag factor to apply when overspeeding
	// const float OverspeedDragFactor = 0.0;

	UPROPERTY(Category = SwingSettings)
	float AutoReleaseAngleThreshold = 10.0;

	// How fast the wanted rotation updates with input
	UPROPERTY(Category = SwingSettings)
	float WantedRotationSpeed = 45.0;

	UPROPERTY(Category = "Rumble")
	UForceFeedbackEffect AttachSwingRumble;

	UPROPERTY(Category = "Rumble")
	UForceFeedbackEffect DetachSwingRumble;

	// how long it should take for the niagara rope to reach the target
	const float ExtendRopeDuration = 0.2;

	// how long it should take for the niagara rope to retract back to the player
	const float RetractRopeDuration = 0.3;
}