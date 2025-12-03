class UTundraPlayerSnowMonkeySettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Tint")
	FLinearColor MorphPlayerTint = FLinearColor::Gray;

	UPROPERTY(Category = "Tint")
	FLinearColor MorphShapeTint = FLinearColor::Gray;

	UPROPERTY(Category = "Movement|Gravity")
	float GravityAmount = 5750.0;

	UPROPERTY(Category = "Movement|Gravity")
	float TerminalVelocity = 5000.0;

	UPROPERTY(Category = "Movement|Gravity")
	float GravityBlendTime = 0.5;

	UPROPERTY(Category = "Movement|Gravity")
	float MonkeyToPlayerGravityBlendTime = 1.6;

	// If we press the jump button. We are guaranteed to get this amount
	UPROPERTY(Category = "Movement|Jump")
	float MinimumJumpInputTime = 0.2;

	// How long can we keep pressing the jump input
	UPROPERTY(Category = "Movement|Jump")
	float MaximumJumpInputTime = 0.5;

	// Upwards impulse applied while jumping
	UPROPERTY(Category = "Movement|Jump")
	float JumpImpulse = 2700.0;
	
	// How much of the horizontal velocity should we get when we jump
	UPROPERTY(Category = "Movement|Jump")
	float InitialHorizontalJumpVelocityMultiplier = 0.3;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MinimumInput = 0.4;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MinimumSpeed = 300.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MaximumSpeed = 1100.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float AccelerationInterpSpeed = 6.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float DecelerationInterpSpeed = 5.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float TurnMultiplier = 2.5;

	UPROPERTY(Category = "Movement|Floor Motion")
	float TurnAroundDuration = 0.5;

	UPROPERTY(Category = "Movement|Floor Motion")
	float TurnAroundRotationDuration = 0.5;

	// How fast do we move while climbing the ceiling
	UPROPERTY(Category="Climbing")
	float CeilingMovementSpeed = 1250;

	// How fast the velocity interps to the target velocity
	UPROPERTY(Category="Climbing")
	float CeilingVelocityInterpSpeed = 4000.0;

	// The force applied when jumping off
	UPROPERTY(Category="Climbing")
	float CeilingMovementJumpOffForceSpeed = 1200;

	// The distance to ceiling where the climb animation should start playing
	UPROPERTY(Category="Climbing")
	float CeilingClimbAnimationTriggerDistance = 500.0;

	/** If we have a climbable ceiling this many units above our heads, apply impulse to reach it */
	UPROPERTY(Category="Climbing")
	float CeilingCoyoteMaxVerticalDistance = 500.0;

    /** Will trace in horizontal velocity direction to see if there is a ceiling in the direction the player is heading. */
    UPROPERTY(Category="Climbing")
    float CeilingCoyoteMaxHorizontalDistance = 500.0;

	/** This impulse will be what is left of the velocity when reaching the ceiling, can make the jump feel more snappy or less snappy */
	UPROPERTY(Category="Climbing")
	float CeilingCoyoteAdditionalImpulse = 100.0;

	UPROPERTY(Category="Climbing")
    float CeilingCoyoteAdditionalHorizontalImpulse = 200.0;

	UPROPERTY(Category="Climbing")
	float CeilingCoyoteMinEnterTime = 0.0001;

	UPROPERTY(Category="Climbing")
	float CeilingCoyoteMaxEnterTime = 0.4;

	/** If we have a climbable ceiling this many units above our heads, apply impulse to reach it. NOTE!!! This is for jumping in monkey form, not the same as the impulse added when transforming. */
	UPROPERTY(Category="Climbing")
	float CeilingSuckupMaxVerticalDistance = 200.0;

	 /** Will trace in horizontal velocity direction to see if there is a ceiling in the direction the player is heading. */
    UPROPERTY(Category="Climbing")
    float CeilingSuckupMaxHorizontalDistance = 200.0;

	/** This impulse will be what is left of the velocity when reaching the ceiling, can make the jump feel more snappy or less snappy */
	UPROPERTY(Category="Climbing")
	float CeilingSuckupAdditionalImpulse = 500.0;

	UPROPERTY(Category="Climbing")
	float CeilingSuckupMinEnterTime = 0.0001;

	UPROPERTY(Category="Climbing")
	float CeilingSuckupMaxEnterTime = 0.4;

	/* If the player is trying to move off the edge of a ceiling we slide against the edge, this setting will treat slide speeds lower than the value as nothing. */
	UPROPERTY(Category="Climbing")
	float CeilingEdgeSlideMinSpeed = 300.0;

	/* Offset WorldPivotOffset this much downwards when at the ceiling. */
	UPROPERTY(Category="Climbing")
	float CeilingCameraSettingsPivotOffsetDistance = 400.0;

	/* When the player is this far away from the ceiling, start blending in the camera. */
	UPROPERTY(Category="Climbing")
	float CeilingCameraSettingsAlphaBlendDistance = 800.0;

	/** The cooldown for how often you can ground slam */
	UPROPERTY(Category="Ground Slam")
	float GroundSlamCooldown = 0.0;

	/** Let's monkey rotate while slamming, used for walking stick scenario */
	UPROPERTY(Category="Ground Slam")
	bool bAllowSlamRotation = false;

	/** Ground Slam Radius */
	UPROPERTY(Category="Ground Slam")
	float GroundSlamRadius = 200;

	UPROPERTY(Category="Ground Slam|Grounded")
	float GroundedGroundSlamFrictionBeforeSlam = 3.0;

	/* How long into the grounded ground slam to still allow a shapeshift back to player */
	UPROPERTY(Category="Ground Slam|Grounded")
	float GroundSlamShapeshiftAllowTime = 0.5;

	/** How long movement will be locked when ground slamming from an already grounded state */
	UPROPERTY(Category="Ground Slam|Grounded")
	float GroundedGroundSlamLockedTime = 1.1;

	/** How long we stay in air before we ground slam */
	UPROPERTY(Category="Ground Slam|Airborne")
	float GroundSlamAirFloatTime = 0.2;

	/** How long we are locked on the ground before we can move again, only applies for airborne ground slam */
	UPROPERTY(Category="Ground Slam|Airborne")
	float RemainOnGroundTime = 0.6;

	/** How fast we fall in ground pound */
	UPROPERTY(Category="Ground Slam|Airborne")
	float GroundSlamGravityMultiplier = 1.0;

	/* If true will lock movement in airborne ground slam in the air. */
	UPROPERTY(Category="Ground Slam|Airborne")
	bool bLockMovementInAirborneGroundSlamInAir = false;

	/* If true will lock movement in airborne ground slam after you have landed. */
	UPROPERTY(Category="Ground Slam|Airborne")
	bool bLockMovementInAirborneGroundSlamAfterLanded = false;

	UPROPERTY(Category="Throw Gnape")
	float GrabGnapeRange = 700.0;

	UPROPERTY(Category="Throw Gnape")
	float GrabGnapeRadius = 400.0;

	UPROPERTY(Category="Throw Gnape")
	float SlamInsteadOfGrabAroundTreeguardianRange = 400.0;

	UPROPERTY(Category="Throw Gnape")
	float GrabbedGnapeMoveSpeed = 700.0;

	UPROPERTY(Category="Throw Gnape")
	float ThrowGnapeRange = 6000.0;

	UPROPERTY(Category="Throw Gnape")
	float ThrowGnapeRadius = 2200.0;

	UPROPERTY(Category="EffectsDistance")
	float FXIsFarAwayDistance = 3000.0;
}