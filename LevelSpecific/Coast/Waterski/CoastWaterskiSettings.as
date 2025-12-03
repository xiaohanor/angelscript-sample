class UCoastWaterskiSettings : UHazeComposableSettings
{
	/* -1.0 will just use the current movement gravity settings, if >=0 this will be used instead. */
	UPROPERTY(Category = "Gravity")
	float WaterskiGravityForce = -1.0;

	UPROPERTY(Category = "Jump")
	float JumpImpulse = 2000.0;

	/* How long to wait before allowing another jump if we just jumped */
	UPROPERTY(Category = "Jump")
	float JumpCooldown = 0.5;

	UPROPERTY(Category = "Train Line")
	float EnterLerpDuration = 2.0;

	/* The length of the line the player holds that is attached to the attach point */
	UPROPERTY(Category = "Train Line")
	float TargetLineLength = 5000.0;

	/* How long it will take the line to accelerate to the current target. */
	UPROPERTY(Category = "Train Line")
	float LineLengthAccelerationDuration = 3.0;

	UPROPERTY(Category = "Train Line")
	float TargetLineLengthSinMaxOffset = 200.0;

	/* How long a full cycle of the sin wave will take  */
	UPROPERTY(Category = "Train Line")
	float TargetLineLengthSinCycleDuration = 10.0;

	/* 0 means you can't steer left and right at all, 90 means you can steer up to perpendicular to the train's forward. */
	UPROPERTY(Category = "Steering")
	float MaxWaterskiAngles = 80.0;

	/* How fast overall we steerback to center and steer away using input */
	UPROPERTY(Category = "Steering")
	float SteerSpeed = 300000.0;

	/* How fast overall we steerback to center and steer away using input */
	UPROPERTY(Category = "Steering")
	float AirSteerSpeed = 200000.0;

	/* Faster speeds than this will be clamped */
	UPROPERTY(Category = "Steering")
	float MaxHorizontalSpeed = 70000.0;

	/* How fast the steer speed interps to steer speed */
	UPROPERTY(Category = "Steering")
	float SteerSpeedInterpSpeed = 1.0;

	/* How fast the wake speed interps up to target wake speed */
	UPROPERTY(Category = "Steering")
	float WakeSpeedIncreaseInterpSpeed = 1.0;

	/* How fast the wake speed interps down to target wake speed */
	UPROPERTY(Category = "Steering")
	float WakeSpeedDecreaseInterpSpeed = 0.3;

	/* This acceleration is applied upwards when the player is underwater, higher value means player wont be underwater as long */
	UPROPERTY(Category = "Buoyancy")
	float BuoyancyAccelerationSpeed = 60000;

	/* When in air, the buoyancy acceleration will lerp to this value */
	UPROPERTY(Category = "Buoyancy")
	float BuoyancyMinAccelerationSpeed = 20000.0;

	/* How long it will take to lerp between buoyancy min acceleration and buoyancy acceleration */
	UPROPERTY(Category = "Buoyancy")
	float BuoyancyAccelerationLerpDuration = 2.0;

	/* This is the max vertical upwards speed the player can have underwater, higher value means the player will fly higher out of the water */
	UPROPERTY(Category = "Buoyancy")
	float BuoyancyMaxVerticalSpeed = 1500.0;

	/* This speed is deducted from the player each time the player hits the surface, higher value means the water surface will feel stiffer. */
	UPROPERTY(Category = "Buoyancy")
	float VerticalSpeedToDeductWhenHittingSurface = 0.0;

	/* This will be multiplied with the current vertical speed and then deducted from the vertical speed between 0 and 1. values >0 will override the above vertical speed to deduct */
	UPROPERTY(Category = "Buoyancy")
	float VerticalSpeedPercentageToDeductWhenHittingSurface = 0.8;

	/* When player's root is this far under the water surface, the full acceleration speed, when at the water surface, 0 acceleration speed will be applied */
	UPROPERTY(Category = "Buoyancy")
	float BuoyancyAlphaDistance = 50.0;

	UPROPERTY(Category = "Camera")
	float PointOfInterestBlendInTime = 1.0;

	UPROPERTY(Category = "Camera")
	float PointOfInterestSplineDistanceOffset = 10000.0;

	UPROPERTY(Category = "Camera")
	float PointOfInterestMaxTurnOffsetInDegrees = 22.5;

	UPROPERTY(Category = "Camera")
	float SpeedInterpSpeed = 2.0;

	UPROPERTY(Category = "Camera")
	FVector PointOfInterestWorldOffset = FVector(0.0, 0.0, -3900.0);

	UPROPERTY(Category = "Boost")
	float BoostZoneDecelerationSpeed = 1500.0;
	
	UPROPERTY(Category = "Boost")
	float BoostZoneMinSpeed = -500.0;

	UPROPERTY(Category = "Boost")
	float BoostZoneEaseOutStartDistance = 500.0;
}