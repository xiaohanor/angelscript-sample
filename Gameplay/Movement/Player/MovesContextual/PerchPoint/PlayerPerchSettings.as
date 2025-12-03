class UPlayerPerchSettings : UHazeComposableSettings
{
	/***	PerchPointSettings	***/


	/***	SideScrollerSettings ***/
	const float HorizontalDeadZone = 0.3;

 	const float TurnaroundDuration = 0.33;

	/***	PerchSplineSettings	***/

	UPROPERTY()
	float MaxSpeed = 450;

	UPROPERTY()
	float MinSpeed = 150;

	UPROPERTY()
	float MaxSprintSpeed = 550;

	UPROPERTY()
	float Acceleration = 1500;

	UPROPERTY()
	float Deceleration = 1500;

	UPROPERTY()
	float FacingDirectionInterpSpeed = 11.0;

	const float PerchSplineJumpFacingInterpSpeed = 4.0;

	//Max height offset based on distance/velocity when triggering Grounded Enter
	const float EnterHeightOffset = 100;
	const float EnterDuration = 0.36;

	const float PERCH_MOVEMENT_DEADZONE_ANGLE = 80;
	const float PERCH_MOVEMENT_STRAIGHTAHEAD_ANGLE = 40;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashDuration = 0.45;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashAccelerationDuration = 0.1;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashDecelerationDuration = 0.35;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashCooldown = 0.3;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashDistance = 450.0;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashExitSpeed = 550.0;

	UPROPERTY(Category = "Perch Spline Dash")
	float DashCameraSettingsLingerTime = 0.1;
	
}