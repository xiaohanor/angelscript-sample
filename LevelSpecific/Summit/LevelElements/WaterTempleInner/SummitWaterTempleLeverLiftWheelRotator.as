class ASummitWaterTempleLeverLiftWheelRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AKineticMovingActor Lift;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpinsPerTrip = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (ClampMin = -1.0, ClampMax = 1.0))
	FRotator RotationAxis = FRotator(1.0, 0.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		int ReachedForwardCount, ReachedBackwardCount;
		float Alpha = Lift.GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount);

		TEMPORAL_LOG(this)
			.Value("Alpha", Alpha)
		;

		//- on alpha -> thought it looked nicer when rotating towards the move direction rather than opposite
		// <3 John
		FRotator NewRotation = RotationAxis * RotationSpinsPerTrip * 360.0 * -Alpha;
		SetActorRelativeRotation(NewRotation.Quaternion());
	}
};