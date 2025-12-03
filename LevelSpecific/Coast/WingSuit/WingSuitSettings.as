class UWingSuitSettings : UHazeComposableSettings
{
	/** The falling speed required by the player to activate wingsuit */
	UPROPERTY(Category = "Activation")
	float PlayerFallSpeedActivation = 1500.0;

	/** How fast we want to move without input
	 * @ X; forward
	 * @ Y; Up
	 */
	UPROPERTY(Category = "Movement")
	FVector2D IdleTargetMoveSpeed = FVector2D(4000.0, -300.0);

	/** How fast we reach 'IdleTargetMoveSpeed' when we have to increase to reach it */
	UPROPERTY(Category = "Movement|Idle")
	FVector2D IncreaseToIdleSpeedAccelerationDuration = FVector2D(1.0, 1.0);

	/** How fast we reach 'IdleTargetMoveSpeed' when we have to decrease to reach it */
	UPROPERTY(Category = "Movement|Idle")
	FVector2D DecreaseToIdleSpeedAccelerationDuration = FVector2D(1.0, 1.0);


	/** How fast we want to move when at max pitch up
	 * @ X; forward
	 * @ Y; Up
	 */
	UPROPERTY(Category = "Movement")
	FVector2D PitchUpTargetMoveSpeed = FVector2D(2500.0, 500.0);

	/** How fast we reach 'PitchUpTargetMoveSpeed' when we have to increase to reach it */
	UPROPERTY(Category = "Movement|PitchUp")
	FVector2D IncreaseToPitchUpMoveSpeedAccelerationDuration = FVector2D(1.0, 1.0);

	/** How fast we reach 'PitchUpTargetMoveSpeed' when we have to decrease to reach it */
	UPROPERTY(Category = "Movement|PitchUp")
	FVector2D DecreaseToPitchUpMoveSpeedAccelerationDuration = FVector2D(1.0, 1.0);

	/** How fast we want to move when at max pitch down
	 * @ X; forward
	 * @ Y; Up
	 */
	UPROPERTY(Category = "Movement")
	FVector2D PitchDownTargetMoveSpeed = FVector2D(3000.0, -1600);

	/** How fast we reach 'PitchDownTargetMoveSpeed' when we have to increase to reach it */
	UPROPERTY(Category = "Movement|PitchDown")
	FVector2D IncreaseToPitchDownMoveSpeedAccelerationDuration = FVector2D(1.0, 1.0);

	/** How fast we reach 'PitchDownTargetMoveSpeed' when we have to decrease to reach it */
	UPROPERTY(Category = "Movement|PitchDown")
	FVector2D DecreaseToPitchDownMoveSpeedAccelerationDuration = FVector2D(1.0, 1.0);

	/* If true, the player will not be able to yaw in the world, turning left/right will only move the player left/right */
	UPROPERTY(Category = "Movement")
	bool bLockYawRotation = false;

	UPROPERTY(Category = "Movement")
	float LockedYawSidewaysMovementSpeed = 2000.0;

	UPROPERTY(Category = "Movement")
	float LockedYawSidewaysAccelerationDuration = 1.5;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect PitchDownMoveSpeedRumleEffect;

	/** How much the controller should rumble
	 * @ Time; The pitch down move speed alpha (speed in relation to 'PitchDownTargetMoveSpeed')
	 * @ Value; The rumble amount
	 */
	UPROPERTY(Category = "ForceFeedback")
	FRuntimeFloatCurve PitchDownMoveSpeedRumleAmount;
	default PitchDownMoveSpeedRumleAmount.AddDefaultKey(0.0, 0.0);
	default PitchDownMoveSpeedRumleAmount.AddDefaultKey(0.5, 0.0);
	default PitchDownMoveSpeedRumleAmount.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "ForceFeedback")
	TSubclassOf<UCameraShakeBase> PitchDownCameraShake;

	/** How much the camera should shake
	 * @ Time; The pitch down move speed alpha (speed in relation to 'PitchDownTargetMoveSpeed')
	 * @ Value; The camera shake scale
	 */
	UPROPERTY(Category = "ForceFeedback")
	FRuntimeFloatCurve PitchDownMoveSpeedCameraShakeScale;
	default PitchDownMoveSpeedCameraShakeScale.AddDefaultKey(0.0, 0.0);
	default PitchDownMoveSpeedCameraShakeScale.AddDefaultKey(0.5, 0.0);
	default PitchDownMoveSpeedCameraShakeScale.AddDefaultKey(1.0, 1.0);
	
	/** 
	 * -1, full pitch down
	 * 1, full pitch up.
	 * value, How fast the move speed should change
	 */
	// UPROPERTY(Category = "Movement")
	// FRuntimeFloatCurve PitchTargetMoveSpeedAcceleration;
	// default PitchTargetMoveSpeedAcceleration.AddDefaultKey(-1.0, 4.0);
	// default PitchTargetMoveSpeedAcceleration.AddDefaultKey(0.0, 1.0);
	// default PitchTargetMoveSpeedAcceleration.AddDefaultKey(1.0, 4.0);

	/** How fast we can rotate the wingsuit */
	UPROPERTY(Category = "Rotation|Movement Direction")
	float MaxRotationSpeed = 100.0;

	/** How fast we reach the max rotation speed when having rotation input */
	UPROPERTY(Category = "Rotation|Movement Direction")
	float IncreaseToRotationMaxSpeedAcceleration = 500.0;

	/** How fast we reach zero rotation when not having rotation input */
	UPROPERTY(Category = "Rotation|Movement Direction")
	float DecreaseToRotationZeroSpeedAcceleration = 500.0;

	/** The max angle that you can pitch up */
	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchUpMaxAngle = 20.0;

	/** The max angle you can pitch down */
	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchDownMaxAngle = 45.0;

	/** How fast you reach the pitch up max */
	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchUpAcceleration = 4.0;

	/** How fast you reach the pitch down max */
	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchDownAcceleration = 10.0;

	/** How fast you reach the pitch idle when not giving input */
	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchToIdleAcceleration = 0.7;

	UPROPERTY(Category = "Rotation|Movement Pitch")
	float TargetPitchOffset = 0.0;

	UPROPERTY(Category = "Rotation|Movement Pitch")
	float PitchOffsetInterpSpeed = 3.0;

	/** How close to the ground should we deactivate. Only used if >= 0 */
	UPROPERTY(Category = "Deactivation")
	float GroundDistanceDeactivation = -1;

	/** The distance we start rumble at. Only used if > 0 */
	UPROPERTY(Category = "ForceFeedback")
	float StartRumbleGroundDistance = 1000.0;
	
	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect GroundDistanceRumbleEffect;

	/** How much the controller should rumble depending on how close to the ground we are
	 * @ Time; Distance to ground alpha where 1 is on the ground (0 -> 1 should be used)
	 * @ Value; The rumble amount
	 */
	UPROPERTY(Category = "ForceFeedback")
	FRuntimeFloatCurve GroundDistanceRumble;
	default GroundDistanceRumble.AddDefaultKey(0.0, 0.0);
	default GroundDistanceRumble.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "ForceFeedback")
	TSubclassOf<UCameraShakeBase> GroundDistanceCameraShake;

	/** How much the camera should shake depending on how close to the ground we are
	 * @ Time; Distance to ground alpha where 1 is on the ground (0 -> 1 should be used)
	 * @ Value; The camera shake scale
	 */
	UPROPERTY(Category = "ForceFeedback")
	FRuntimeFloatCurve GroundDistanceCameraShakeCurve;
	default GroundDistanceCameraShakeCurve.AddDefaultKey(0.0, 0.0);
	default GroundDistanceCameraShakeCurve.AddDefaultKey(1.0, 1.0);

	// At what angle from the impact normal are we going to die at
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float WallImpactDeathAngleMax = 7.0;

	// At what angle from the impact normal are we going to die at
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float CeilingImpactDeathAngleMax = 7.0;

	// At what angle from the impact normal are we going to die at
	UPROPERTY(Category = "Death", meta = (ClampMin = "0.0", ClampMax = "89.0"))
	float GroundImpactDeathAngleMax = 7.0;

	// How far from the other player we respawn when we are ahead. Only used if >= 0
	UPROPERTY(Category = "Death")
	float MaxRespawnDistanceWhenAHead = -1;

	// How far from the other player we respawn when we are behind. Only used if >= 0
	UPROPERTY(Category = "Death")
	float MaxRespawnDistanceWhenBehind = -1;

	// How long time we will be steering after we die,
	UPROPERTY(Category = "Death")
	float AutoSteeringTimeAfterDeath = 3;

	/** How much we tilt the camera downwards when pitching down the wingsuit
	 * @ Time; the alpha value between 0 -> 1
	 * @ Value, how much we should pitch the camera.
	 */
	UPROPERTY(Category = "Camera")
	FRuntimeFloatCurve PitchDownCameraPitchAmount;
	default PitchDownCameraPitchAmount.AddDefaultKey(0.0, 0.0);
	default PitchDownCameraPitchAmount.AddDefaultKey(1.0, 35.0);

	/** The speed used to apply camera speed settings 
	 * When the lowest speed is reached, the lowest settings are used
	 * When the highest speed is reached, the highest settings are used
	*/
	UPROPERTY(Category = "Camera")
	FHazeRange CameraSpeedRange = FHazeRange(2500, 3500);

	/** Field of view depending on the 'CameraSpeedRange'
	 */
	UPROPERTY(Category = "Camera")
	FHazeRange CameraSpeedFov = FHazeRange(7.0, 20.0);

	UPROPERTY(Category = "Camera")
	FHazeRange CameraHorizontalOffset = FHazeRange(500.0, 500.0);

	/** How high the camera will be over the player */
	UPROPERTY(Category = "Camera")
	float CameraVerticalOffset = 120.0;

	UPROPERTY(Category = "RubberBand")
	FWingSuitRubberBandData RubberbandSettings;

	/** Is barrel roll active */
	UPROPERTY(Category = "Barrel Roll")
	bool bCanActivateBarrelRoll = true;

	/** How long does it take to perform the entire barrel roll */
	UPROPERTY(Category = "Barrel Roll")
	float BarrelRollActionTime = 0.8;

	/** How long until we can roll again */
	UPROPERTY(Category = "Barrel Roll")
	float BarrelRollCooldownTime = 0.5;

	/** What move speed will the barrel roll give in the left / right direction. 
	 * Based on the current alpha time from 'BarrelRollActionTime'
	 */
	UPROPERTY(Category = "Barrel Roll")
	FRuntimeFloatCurve BarrelRollMovementSpeedBasedOnAlpha;
	default BarrelRollMovementSpeedBasedOnAlpha.AddDefaultKey(0, 0);
	default BarrelRollMovementSpeedBasedOnAlpha.AddDefaultKey(0.25, 5500);
	default BarrelRollMovementSpeedBasedOnAlpha.AddDefaultKey(1, 1500);

	/** Control the barrel roll rotation
	 * Based on the current alpha time from 'BarrelRollActionTime'
	 */
	UPROPERTY(Category = "Barrel Roll")
	FRuntimeFloatCurve BarrelRollRotationBasedOnAlpha;
	default BarrelRollRotationBasedOnAlpha.AddDefaultKey(0, 0);
	default BarrelRollRotationBasedOnAlpha.AddDefaultKey(0.25, 90);
	default BarrelRollRotationBasedOnAlpha.AddDefaultKey(0.5, 180);
	default BarrelRollRotationBasedOnAlpha.AddDefaultKey(0.75, 270);
	default BarrelRollRotationBasedOnAlpha.AddDefaultKey(1.0, 360);

	/* Anticipation delay prior to actually showing grapple hook */
	UPROPERTY(Category = "Grapple")
	float GrappleAnticipationDelay = 0.2;

	/* How long it takes for the grapple hook to reach the grapple point */
	UPROPERTY(Category = "Grapple")
	float GrappleEnterDuration = 1;

	UPROPERTY(Category = "Grapple")
	float GrappleAcceleration = 5000.0;

	UPROPERTY(Category = "Grapple")
	float GrappleMaxSpeed = 20000.0;
}

struct FWingSuitRubberBandData
{
	/** How fast we can move when we are ahead at the max distance between the players allowed
	 * This is in relation to 'AHeadTriggerDistance'
	 */
	UPROPERTY(Category = "Rubberband", meta = (ClampMin = "-1.0", ClampMax = "1.0", UIMin = "-1.0", UIMax = "1.0"))
	float BonusSpeedWhenAhead = -0.04;

	/** How fast we can move when we are behind at the max distance between the players allowed
	 * This is in relation to 'BehindTriggerDistance'
	 */
	UPROPERTY(Category = "Rubberband", meta = (ClampMin = "-1.0", ClampMax = "1.0", UIMin = "-1.0", UIMax = "1.0"))
	float BonusSpeedWhenBehind = 0.1;

	/** 
	 * How long it will take until we apply the new rubberband settings
	 */
	UPROPERTY(Category = "Rubberband")
	float BonusSpeedApplyDelay = 2;

	/** 
	 * How fast we will apply the rubberband settings
	 */
	UPROPERTY(Category = "Rubberband")
	float BonusSpeedApplySpeed = 2.0;

	/* When the players are this distance between each other they will not get any behind or ahead bonus speed. */
	UPROPERTY(Category = "Rubberband")
	float BonusSpeedTolerance = 0.0;

	/* When the players are this distance from each other the bonus speed will start to lerp down to 0 as the distance reaches tolerance distance. This distance will be added with the tolerance distance. */
	UPROPERTY(Category = "Rubberband")
	float BonusSpeedLerpDownAdditionalDistance = 1000.0;
}