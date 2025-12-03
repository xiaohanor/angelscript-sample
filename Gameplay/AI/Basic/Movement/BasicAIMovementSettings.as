class UBasicAIMovementSettings : UHazeComposableSettings
{
	// Default friction when on ground
    UPROPERTY(Category = "Movement")
	float GroundFriction = 8.0;

	// Default friction when in air
    UPROPERTY(Category = "Movement")
	float AirFriction = 1.2;

	// Distance at which we consider ourselves at a spline when following it
    UPROPERTY(Category = "Movement")
	float SplineFollowCaptureDistance = 100.0;

	// Additional spline-orthogonal friction when sliding onto spline
    UPROPERTY(Category = "Movement")
	float SplineCaptureBrakeFriction = 4.0;

	// How fast we change facing
    UPROPERTY(Category = "Movement")
	float TurnDuration = 0.5;

	// How fast we stop turning when we no longer have a focus (higher values is faster stop)
    UPROPERTY(Category = "Movement")
	float StopTurningDamping = 5.0;

	// TODO: HACK! For now we use this to determine the movement used for animation.
	UPROPERTY(Category = "Movement")
	bool bUseTeleportingAnimationMovement = false;
}