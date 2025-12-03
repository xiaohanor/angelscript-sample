class UTundraPlayerOtterSwimmingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Underwater)
	float UnderwaterDesiredSpeed = 700.0;

	UPROPERTY(Category = Underwater)
	float UnderwaterMinimumSpeed = 200;

	UPROPERTY(Category = Underwater)
	float UnderwaterDesiredSpeedInterpSpeed = 2.2;

	UPROPERTY(Category = Underwater)
	bool bUseConstantInterpRotationUnderwater = true;

	UPROPERTY(Category = Underwater)
	float InterpRotationSpeedUnderwater = 200.0;

	// The Force you jump out of the water with when swimming up to the surface
	UPROPERTY(Category = Underwater|SurfaceJump)
	float UnderwaterJumpOutOfStrength = 0;

	// You need to swim upwards for this duration to trigger a jump out of
	UPROPERTY(Category = Underwater|SurfaceJump)
	float UnderwaterSwimUpTimeRequiredForJump = 0;

	UPROPERTY(Category = Underwater|SurfaceJump)
	float UnderwaterBreachjumpAirSpeed = 600; 

	//Aligned input size required to trigger jumpout
	UPROPERTY(Category = Underwater|SurfaceJump)
	float SideScrollerJumpOutDeadZone = 0.5;

	UPROPERTY(Category = Surface)
	float SurfaceJumpOutOfStrength = 950;

	UPROPERTY(Category = Surface)
	float SurfaceDesiredSpeed = 600.0;
	
	UPROPERTY(Category = Surface)
	float SurfaceMinimumSpeed = 200;

	UPROPERTY(Category = Surface)
	float SurfaceDesiredSpeedInterpSpeed = 2.0;

	UPROPERTY(Category = Surface)
	bool bForceSurfaceSwimming = false;

	UPROPERTY(Category = Surface)
	float SurfaceCooldown = 1.5;

	UPROPERTY(Category = Surface)
	float SurfaceStiffness = 60.0;

	UPROPERTY(Category = Surface)
	float SurfaceDamping = 0.4;

	UPROPERTY(Category = Surface)
	float SurfaceTraceRange = 200.0;

	UPROPERTY(Category = Surface)
	float SurfaceRangeFromUnderwater = 90.0;

	UPROPERTY(Category = Surface)
	float UnderwaterWaterRangeFromSurface = 25.0;

	UPROPERTY(Category = Surface)
	float SurfaceRangeFromAboveSurface = 150.0;

	UPROPERTY(Category = Surface)
	float VerticalVelocityForUnderWaterSwim = -2000;

	UPROPERTY(Category = Surface|Dive)
	float DiveDesiredHorizontalSpeed = 300.0;

	UPROPERTY(Category = Surface|Dive)
	float DiveDesiredHorizontalSpeedInterpSpeed = 1.0;

	UPROPERTY(Category = Surface|Dive)
	float DiveStrength = 800.0;

	//StickInput aligned with WorldDown to trigger dive
	UPROPERTY(Category = Surface|Dive)
	float SideScrollerDiveDeadZone = 0.4;

	// If true will dash in the direction of the movemnt input, if false it will dash in the current velocity direction
	UPROPERTY(Category = "Swim Dash")
	bool bSwimDashFollowMovementInput = false;

	UPROPERTY(Category = "Swim Dash")
	float SwimDashRotationInterpSpeed = PI;

	UPROPERTY(Category = "Swim Dash")
	float DashDuration = 0.5;

	UPROPERTY(Category = "Swim Dash")
	float DashAccelerationDuration = 0.1;

	UPROPERTY(Category = "Swim Dash")
	float DashDecelerationDuration = 0.1;

	UPROPERTY(Category = "Swim Dash")
	float DashCooldown = 0.5;

	UPROPERTY(Category = "Swim Dash")
	float DashDistance = 600.0;

	UPROPERTY(Category = "Swim Dash")
	float DashExitSpeed = 700.0;

	UPROPERTY(Category = "Swim Dash")
	float DashCameraSettingsLingerTime = 0.1;

	UPROPERTY(Category = "Swim Dash")
	float DashAlignWithVelocityMinimumSpeed = 25;

	UPROPERTY(Category = "Swim Dash")
	float MaxDashOutOfSurfaceSpeed = 1500.0;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_SwimDashRotationInterpSpeed = PI;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_DashDuration = 0.5;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_DashAccelerationDuration = 0.1;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_DashDecelerationDuration = 0.1;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_DashDistance = 600.0;

	UPROPERTY(Category = "Swim Underwater Dash")
	float Underwater_DashExitSpeed = 700.0;
	}