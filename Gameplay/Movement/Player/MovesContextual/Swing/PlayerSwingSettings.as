class UPlayerSwingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = SwingSettings)
	float GravityAcceleration = 2400.0;

	UPROPERTY(Category = SwingSettings)
	float InputAcceleration = 800.0;

	// If our speed in the swing exceeds this, apply the extra overspeed drag
	UPROPERTY(Category = SwingSettings)
	float MaximumSwingVelocityBeforeOverspeedDrag = 1750.0;

	/*
		Exposed to the swing point
	*/
	UPROPERTY(Category = SwingPointSettings)
	float TetherLength = 800.0;

	// How much speed giving full input gives us, Speed is calculated as a factor of Tetherlength / BaseRopeLength in swing movement
	const float InputSpeed = 850;

	// Baseline ropelength calculated for to give full speed
	const float RopeLength = 800;

	//Drag used to align the players velocity with the swing direction
	const float HorizontalDragCoefficient = 0.3;

	//Drag affecting our aligned forward swing
	const float VerticalDragCoefficient = 0.6;

	//Drag affecting the player when no input is given
	const float NoInputDragCoefficient = 0.55;

	// Additional drag factor to apply when overspeeding
	const float OverspeedDragFactor = 0.1;

	// how long it should take for the niagara rope to reach the target
	const float ExtendRopeDuration = 0.2;

	// how long it should take for the niagara rope to retract back to the player
	const float RetractRopeDuration = 0.3;
}

UCLASS(meta=(ComposeSettingsOnto = "UPlayerSwingSettings"))
class UPlayerSwingPointSettings : UHazeComposableSettings
{
	UPROPERTY(Category = SwingPointSettings)
	float TetherLength = 800.0;
}