class USkylineBallBossSettings : UHazeComposableSettings
{
	// -------------------------------
	// Health and damage

	float MaxHealth = 1.0;
	UPROPERTY(Category = "Health")
	int HealthSegments = 4;

	float FloatSegments = float(HealthSegments);
	float SegmentHealth = MaxHealth / FloatSegments;

	UPROPERTY(Category = "Health")
	float DetonatorDamage = SegmentHealth / 3.0;
	UPROPERTY(Category = "Health")
	float DamageRequiredToBreakEye = 0.50;
	UPROPERTY(Category = "Health")
	float DetonatorDamageOffEye = 0.05;
	UPROPERTY(Category = "Health")
	float DamageRequiredToActivateShield = 0.25;
	UPROPERTY(Category = "Health")
	float ChargeLaserDamage = SegmentHealth / 3.0;
	UPROPERTY(Category = "Health")
	float WeakpointHealth = SegmentHealth;
	UPROPERTY(Category = "Health")
	int WeakpointNumHits = 8;

	// -------------------------------
	// Chase

	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopMioOn1 = 2.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopGrappleFailed1 = 0.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopAlignMioToStage = 0.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopShieldShockwave = 1.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopMioOff2 = 4.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopGrappleFailed2 = 0.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopMioOn2 = 2.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopMioIn = 2.0;
	UPROPERTY(Category = "Change Phase Dramatic Pause")
	float PauseTopMioInKillWeakpoint = 2.0;

	UPROPERTY(Category = "Blink")
	float BlinkCooldownMax = 15.0;
	UPROPERTY(Category = "Blink")
	float BlinkCooldownMin = 5.0;
	UPROPERTY(Category = "Blink")
	float DoubleBlinkChance = 0.05;

	UPROPERTY(Category = "Chase")
	float ChaseStartWaitElevatorTime = 3.0;

	UPROPERTY(Category = "Chase")
	float ChaseRotationJitterAngle = 4.0;
	UPROPERTY(Category = "Chase")
	float ChaseRotationJitterHitPlayerAngle = 1.0;
	UPROPERTY(Category = "Chase")
	FVector2D ChaseRotationJitterCooldownMinMax = FVector2D(0.2, 0.4);

	// Camera target lerps from between players to in front of players
	// Depending on how close players are to each other
	//
	//                      🎥 cam is centered between players
	// ---->---->--👧🏾-->---->--->----👧🏼>---->---->---->---->
	//              ^   cam max dist  ^
	//
	//                                🎥 cam is in front
	// ---->---->--👧🏾👧🏼-->---->--->---->---->---->---->---->
	//               ^ forw offset max ^
	UPROPERTY(Category = "Chase Camera")
	float SplineDistanceForwardOffsetMax = 600.0;
	UPROPERTY(Category = "Chase Camera")
	float ChaseCameraMaxVerticalOffset = 200.0;
	UPROPERTY(Category = "Chase Camera")
	float MaxAllowedDistanceBetweenPlayers = 2000.0;

	// To avoid camera snapping when players die etc, we have different interpolation durations
	UPROPERTY(Category = "Chase Camera")
	float CamNormalInterpolateDuration = 0.5;
	UPROPERTY(Category = "Chase Camera")
	float CamStartSofterInterpolateDuration = 3.0;
	UPROPERTY(Category = "Chase Camera")
	float CamSofterInterpolateDuration = 3.0;

	// If our spline dist is less than this to a player, we use minimum speed
	// When spline dist exceeds AcceptedDistance we start to lerp towards max speed. 
	// The less MaxDistance is, the quicker we lerp to max speed
	//       min speed used       lerp speeds      max speed used
	// 🔴---->---->---->---->|--👧🏾👧🏼->---->---->|---->---->---->
	//        accepted dist  ^                   ^ player max dist
	UPROPERTY(Category = "Chase Laser")
	float ChaseLaserMinimumSpeed = 350.0;
	UPROPERTY(Category = "Chase Laser")
	float ChaseLaserMaxSpeed = 1000.0;
	UPROPERTY(Category = "Chase Laser")
	float ChaseLaserPlayerAcceptedDistance = 1000.0;
	UPROPERTY(Category = "Chase Laser")
	float ChaseLaserPlayerPlayerMaxDistance = 2000.0;
	UPROPERTY(Category = "Chase Laser")
	float ChaseLaserSpeedAccDuration = 0.5;

	// The laser has AcceleratedTargeting. I'm also having a AcceleratedFloat for the duration of the AcceleratedTargeting
	// Maybe it's cake on cake but it looks nice when we interp for killing Players
	// If player jumps behind laser, accelerate to target and kill them
	//                   !?
	// ---->---->--👧🏾-->🔴---->--👧🏼->---->---->---->---->---->
	UPROPERTY(Category = "Chase Laser")
	float NormalAcceleratedDuration = 4.0;
	UPROPERTY(Category = "Chase Laser")
	float KillPlayerAcceleratedDuration = 2.0;
	UPROPERTY(Category = "Chase Laser")
	float NormalTargetAccDuration = 0.05; // Snap to spline	
	UPROPERTY(Category = "Chase Laser")
	float KillPlayerTargetAccDuration = 2.0;
	UPROPERTY(Category = "Chase Laser")
	float KillPlayerApproxDistanceForInterp = 500.0;

	// -------------------------------
	// CarTower Top Settings ---------

	UPROPERTY(Category = "Feedback")
	float DetonatorOffShieldFlashDuration = 0.0;
	UPROPERTY(Category = "Feedback")
	float DetonatorOffShieldVFXDuration = 2.0;

	UPROPERTY(Category = "ZoeThrowDetonators")
	float ZoeThrowDetonatorSwitchRotationLookAwayAngle = 30.0;
	UPROPERTY(Category = "ZoeThrowDetonators")
	float ZoeThrowDetonatorSwitchRotationTargetCooldown = 5.0;
	UPROPERTY(Category = "ZoeThrowDetonators")
	float ZoeThrowDetonatorAutoAimAngle = 8.0;

	UPROPERTY(Category = "DetonatorHurt")
	float DetonatorHurtRotateStiffness = 100.0;
	UPROPERTY(Category = "DetonatorHurt")
	float DetonatorHurtRotateDampening = 0.3;

	UPROPERTY(Category = "Shield Shockwave")
	float DurationAfterAligningMioToStartShield = 1.0;
	UPROPERTY(Category = "Shield Shockwave")
	float ShieldShockwaveMinRadius = 19.5;
	UPROPERTY(Category = "Shield Shockwave")
	float ShieldShockwaveMaxRadius = 25.0;

	UPROPERTY(Category = "Disintegrate Pulse")
	float DisintegratePulseMinRadius = 5.0;
	UPROPERTY(Category = "Disintegrate Pulse")
	float DisintegratePulseMaxRadius = 100.0;

	UPROPERTY(Category = "Extrude")
	float ExtrudeDuration = 1.0;
	UPROPERTY(Category = "Extrude")
	float ExtrudeRotateStiffness = 20.0;
	UPROPERTY(Category = "Extrude")
	float ExtrudeRotateDampening = 0.6;
	UPROPERTY(Category = "Extrude")
	float ExtrudeAlignRotOffsetMin = 40.0;
	UPROPERTY(Category = "Extrude")
	float ExtrudeAlignRotOffsetMax = 50.0;
	UPROPERTY(Category = "Extrude")
	float ExtrudeRetractGraceTime = 1.0;
}