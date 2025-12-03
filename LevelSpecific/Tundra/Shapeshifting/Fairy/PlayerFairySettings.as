class UTundraPlayerFairySettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Tint")
	FLinearColor MorphPlayerTint = FLinearColor::Gray;

	UPROPERTY(Category = "Tint")
	FLinearColor MorphShapeTint = FLinearColor::Gray;

	/* If player pressed jump less than this time, it will count as pressing now, applies to leap also */
	UPROPERTY()
	float JumpInputQueuingDuration = 0.1;

	/* The vertical impulse that will be applied when fairy is jumping */
	UPROPERTY()
	float JumpVerticalImpulse = 750;

	/* This friction will be applied when the fairy is grounded to slow down it's horizontal velocity */
	UPROPERTY()
	float HorizontalGroundFriction = 8;

	/* This friction will be applied when the fairy is airborne to slow down it's horizontal velocity */
	UPROPERTY()
	float HorizontalAirFriction = 4;

	/* How fast the rotation will respond to the fairy's velocity */
	UPROPERTY()
	float FairyRotationInterpSpeed = 20;

	/* Turn this on if you would like to see a red line that visualizes the steering input vector in wind currents */
	UPROPERTY()
	bool bDebugWindCurrentSteeringInput = false;

	/* Can only leap every n seconds */
	UPROPERTY(Category="Leaping")
	float LeapCooldown = 0.25;

	/* How fast the fairy will interp towards the velocity in leap */
	UPROPERTY(Category="Leaping")
	float LeapingFairyInterpSpeed = 3;

	/* This will limit the max input angle to within the specified degrees. 45 means 45 degrees to both sides of straight forward. 0 means only straight forward, 180 means no limit */
	UPROPERTY(Category="Leaping")
	float MaxLeapingInputAngle = 180;

	/* This offset rotation will be applied to the camera when leaping */
	UPROPERTY(Category="Leaping")
	FRotator OffsetDesiredRotationInLeap = FRotator(-7, 0, 0);

	/* If true, velocity when starting leap will be inherited and then slowly decelerated (the same way the air movement is decelerated) */
	UPROPERTY(Category="Leaping")
	bool bInheritVelocityWhenStartingLeap = true;

	/* From the first leap, this is the maximum height gain */
	UPROPERTY(Category="Leaping")
	float MaxHeightGain = 100.0;

	/* If player falls below this height they will start to loose height */
	UPROPERTY(Category="Leaping")
	float LowHeightBeforeLosingHeight = 50.0;

	/* x: 0 means 0 secs, x: 1 means HeightLossOverTimeCurveDuration secs, y: 0 means 0 height loss, y: 1 means MaxHeightLossSpeed units/s */
	UPROPERTY(Category="Leaping")
	FRuntimeFloatCurve HeightLossOverTimeCurve;

	UPROPERTY(Category="Leaping")
	float HeightLossOverTimeCurveDuration = 3.0;

	/* If the curve is at y: 1, this loss speed will be used */
	UPROPERTY(Category="Leaping")
	float MaxHeightLossSpeed = 250;

	/* Depending on the height alpha of the player in the leap, change gravity, y: 0 is zero gravity, y: 1 is full gravity, x: 0 is at apex of the height, x: 1 is LeapHangTimeCurve seconds after apex */
    UPROPERTY(Category="Leaping")
    FRuntimeFloatCurve LeapHangTimeCurve;

	/* How long the curve will be sampled over, when reached the end, it will continue samping x: 1 to determine gravity */
	UPROPERTY(Category="Leaping")
	float HangTimeTransitionDuration = 1.0;

	/* This is the horizontal speed the fairy leap will be in */
	UPROPERTY(Category="Leaping")
	float LeapHorizontalSpeed = 850;

	/* Precision mode adds air control to the leap and also makes the leap speed slower when leaping sideways or backwards for more fine control */
	UPROPERTY(Category="Leaping|Precision Mode")
	bool bEnableLeapPrecisionMode = false;

	/* This is the max speed you can reach with air control, will be added on top of the leap speed but will not go over leap horizontal speed */
	UPROPERTY(Category="Leaping|Precision Mode")
	float LeapPrecisionHorizontalAirControlMaxSpeed = 400;

	/* This drag will be applied to the air control part of the velocity */
	UPROPERTY(Category="Leaping|Precision Mode")
	float LeapPrecisionHorizontalAirFriction = 4;

	/* When jumping backward or sideways this multiplier will be used and will scale up to 1 when forward */
	UPROPERTY(Category="Leaping|Precision Mode")
	float LeapPrecisionLowestMultiplier = 0.2;

	/* x: 0 is 0 secs after leap, x: 1 is SidewaysMovementDuration secs after leap, y: 0 is 0 sideways offset, y: 1 is SidewaysMovementMaxOffset sideways offset to either the left/right */
	UPROPERTY(Category="Leaping")
	FRuntimeFloatCurve SidewaysMovementShapeCurve;

	UPROPERTY(Category="Leaping")
	float SidewaysMovementDuration = 0.8;

	/* How many times you can leap in a row before touching the ground to reset, negative numbers will mean infinite */
	UPROPERTY(Category="Leaping")
	int MaxAmountOfLeaps = -1;

	/* When leaping, how fast the camera will interp to be behind the fairy */
	UPROPERTY(Category="Leaping")
	float LeapingFollowCameraInterpSpeed = 1;

	/* If true, the player can move the camera while leaping to offset the camera while it follows the fairy from behind */
	UPROPERTY(Category="Leaping")
	bool bAllowLeapingCameraOffset = true;

	/* When this amount of seconds has passed since the last time the player touched the camera control, the camera will go back to following behind the player */
	UPROPERTY(Category="Leaping")
	float CameraFollowAgainDelay = 2.0;

	/* If current vertical velocity is above this value the fairy will not automatically leap on shapeshift */
	UPROPERTY(Category="Leaping")
	float MaxVerticalVelocityToLeapAfterShapeshift = 900.0;

	/* This determines how far ahead the switch move spline targetable is. A higher speed means that it assumes the fairy will reach the spline sooner so the targetable is further back. */
	UPROPERTY(Category="Move Splines")
	float SwitchMoveSplineTargetableAheadReferenceHorizontalSpeed = 1300.0;

	/* This is how far in front of the player (on the spline) that the camera's point of interest will be */
	UPROPERTY(Category="Move Splines")
	float PointOfInterestOffset = 700.0;

	/* Speed of how fast camera rotates, 1 is normal speed, lower is slower */
	UPROPERTY(Category="Move Splines", meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PointOfInterestSpeedMultiplier = 0.2;

	/* This is how much you can turn to offset the point of interest */
	UPROPERTY(Category="Move Splines")
	float PointOfInterestMaxTurnOffsetInDegrees = 40.0;

	/* This is how fast the camera offset turns in point of interest mode */
	UPROPERTY(Category="Move Splines")
	float PointOfInterestTurnOffsetInterpSpeed = 10.5;
}