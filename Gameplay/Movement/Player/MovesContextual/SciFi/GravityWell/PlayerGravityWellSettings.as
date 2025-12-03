class UPlayerGravityWellSettings : UHazeComposableSettings
{	
	/** 
	 * If true, well counts as an elevator
	 * If false, its like a water slide.
	*/
	UPROPERTY(Category = Movement)
	bool bIsVerticalWell = true;

	/* The radius of the well from the center of the spline
		Reload level if you change this with the level open, as all Gravity Wells need to be nudged to use the new value
	*/
	UPROPERTY(meta = (ClampMin="0.0", UIMin="0.0"))
	float Radius = 400.0;

	// How fast we are moving in the well direction
	UPROPERTY(Category = Movement)
	float ForwardSpeed = 400.0;

	UPROPERTY(Category = Movement)
	float ForwardSpeedInterpSpeed = 3.0;

	// How fast we move on the current direction plane (in and out towards the walls)
	UPROPERTY(Category = Movement)
	float PlayerPlaneMoveSpeed = 600.0;

	UPROPERTY(Category = Movement)
	float PullToCenterStrength = 3.0;

	// If this is set to false, the player can float out of the well
	UPROPERTY(Category = Movement)
	bool bLockPlayerInsideWell = true;

	// How close to the edge of the edge of the well the player can get
	UPROPERTY(Category = Movement)
	float LockPlayerMargin = 80.0;

	// only used if >= 0
	UPROPERTY(Category = Launch)
	float LaunchDeactivateAfterDuration = 8.0;

	UPROPERTY(Category = Launch)
	bool LaunchDeactivateOnImpacts = true;

	UPROPERTY(Category = Launch)
	bool LaunchDeactivateOnFalling = false;

	UPROPERTY(Category = Launch)
	bool LaunchDeactivateIfOutsideWell = false;

	UPROPERTY(Category = Launch)
	float LaunchSpeed = 2000.0;

	UPROPERTY(Category = Launch)
	float LaunchGravity = 2000.0;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings = nullptr;

	UPROPERTY(Category = Camera)
	bool bEnableFollowCamera = true;

	/*
		- if 0 will look in the direction of the tangent
		- if greater than 0, will look a point ahead of the player.
			Any overshoot to the target will instead be in the launch direction
	*/
	UPROPERTY(Category = Camera)
	float CameraLookAtDistance = 600.0;
}