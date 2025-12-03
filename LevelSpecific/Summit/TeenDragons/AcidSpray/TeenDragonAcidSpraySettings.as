class UTeenDragonAcidSpraySettings : UHazeComposableSettings
{
	// How long you need to recharge after you stop spraying
	UPROPERTY()
	float SprayRechargeCooldown = 0.015;
	//While firing, if acid amount reaches 0, the % required before firing is allowed again during this input hold.
	UPROPERTY()
	float SprayShootRechargeThreshold = 0.3;
	//Amount reduced per second (Value was 0.35 before removing)
	UPROPERTY()
	float AcidReductionAmount = 0.0;
	//Amount recharged per second when no longer firing
	UPROPERTY()
	float AcidRechargeSpeed = 1.0;
	//Acceleration speed to reach full recharge speed
	UPROPERTY()
	float AcidAccelerationRechargeSpeed = 6.0;
	// After traveling this far, the projectile starts to drop
	UPROPERTY()
	float AcidSprayRange = 6000.0;
	// Radius of puddle placed by spray projectile
	UPROPERTY()
	float PuddleRadius = 200.0;
	// Duration of puddle placed by spray projectile
	UPROPERTY()
	float PuddleDuration = 3.0;

	// Socket name on the dragon that acid should spray from
	UPROPERTY()
	FName ShootSocket = n"Head";
	// Offset from the socket on the dragon that acid should spray from
	UPROPERTY()
	FVector ShootSocketOffset(50.0, 0.0, 0.0);

	// Projectile speed for sprayed acid
	UPROPERTY()
	float ProjectileSpeed = 6000.0;
	
	// Time before projectile returns to pool
	UPROPERTY()
	float ProjectileLiftTime = 0.9;
	// Gravity applied to sprayed acid trajectory
	UPROPERTY()
	float ProjectileGravity = 1000.0;

	UPROPERTY()
	float ProjectileDropOffAlpha = 0.4;

	UPROPERTY()
	float ProjectileDropOffExtraGravity = 6000.0;

	// How large the projectile starts
	UPROPERTY()
	FVector ProjectileStartScale(0.0001, 0.0001, 0.0001);
	// How large the projectile becomes
	UPROPERTY()
	FVector ProjectileEndScale(0.0001, 0.0001, 0.0001);
	// How long it takes to scale the projectile
	UPROPERTY()
	float ProjectileScaleUpDuration = 0.0;
	// How big the trace is for the projectile while in air (scaled by projectile scale)
	UPROPERTY()
	float ProjectileTraceRadius = 0.0;
	// How big the trace is when the projectile lands and hits things (scaled by projectile scale)
	UPROPERTY()
	float ProjectileSplashRadius = 160.0;

	// How much damage per second 
	UPROPERTY()
	float FullSprayDamagePerSecond = 2.0;

	// How long before the spray starts firing
	UPROPERTY()
	float SprayDelay = 0.0;

	// How long until the projectile starts having collision
	UPROPERTY()
	float ProjectileCollisionGraceTime = 0.0;

	// If aim hits something within this distance, it's disregarded for projectile
	UPROPERTY()
	float AimTraceHitDistanceThreshold = 250.0;

	UPROPERTY(Category = "Camera")
	FVector CameraOffset = FVector(200, 125, -100);

}