class UTundraPlayerSnowMonkeyClimbableVineSettings : UHazeComposableSettings
{
	/* Player wont be able to grab another vine before this cooldown is over. */
	UPROPERTY(Category = "Settings")
	float ClimbableVineCooldown = 0.25;

	/* This is the max vertical speed up/down on the vine */
	UPROPERTY(Category = "Settings")
	float VerticalSpeed = 500.0;

	/* How many seconds it will take to accelerate up to vertical speed */
	UPROPERTY(Category = "Settings")
	float VerticalSpeedAccelerationDuration = 0.5;

	UPROPERTY(Category = "Settings")
	float VelocityInterpSpeed = -8.0;

	/* You wont be able to climb below this padding */
	UPROPERTY(Category = "Settings")
	float LowerVinePadding = 100.0;

	/* You wont be able to climb above this padding */
	UPROPERTY(Category = "Settings")
	float UpperVinePadding = 250.0;

	/* This will be multiplied with the monkey's ingoing horizontal velocity to determine the velocity the monkey attach point should be set to. */
	UPROPERTY(Category = "Settings")
	float MonkeyAttachImpulseHorizontalMultiplier = 3.0;

	/* This will be multiplied with the monkey's ingoing vertical velocity to determine the velocity the monkey attach point should be set to. */
	UPROPERTY(Category = "Settings")
	float MonkeyAttachImpulseVerticalMultiplier = 1.0;

	/* Impulse will be applied to all the particles in this radius (linear falloff based on distance) */
	UPROPERTY(Category = "Settings")
	float MonkeyAttachImpulseRadius = 750.0;

	/* The gravity force that will be applied on the vine */
	UPROPERTY(Category = "Settings")
	float GravityForce = 9800.0 * 1.5;

	/* The gravity will be applied to all particles within this radius around the center of the player with a linear falloff based on distance */
	UPROPERTY(Category = "Settings")
	float GravityForceRadius = 750.0;

	/* When the player is within this distance from the vine they will attach to it */
	UPROPERTY(Category = "Enter")
	float DistanceToEnterVine = 200.0;

	/* The impulse that will be applied in the player's forward direction when cancelling or in some other way leaving the vine (except jump) */
	UPROPERTY(Category = "Exit")
	FVector BaseLeaveVineImpulse = FVector(500.0, 0.0, 0.0);

	/* The impulse that will be applied in the player's forward direction when jumping off the vine. */
	UPROPERTY(Category = "Exit")
	FVector JumpLeaveVineImpulse = FVector(2000.0, 0.0, 0.0);
}