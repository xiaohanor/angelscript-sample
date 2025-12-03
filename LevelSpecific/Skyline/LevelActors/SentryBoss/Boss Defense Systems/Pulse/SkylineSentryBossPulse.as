class ASkylineSentryBossPulse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USkylineSentryBossPulseScaleComponent PulseScaleComponent;


	float Speed = 10.0;
	float Acceleration = 10;

	FVector Direction;
	float DistanceTraveled = 0.0;
	float MaxTravelDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MaxTravelDistance == 0.0)
			MaxTravelDistance =  PulseScaleComponent.Radius * 2.0;

		Direction = (PulseScaleComponent.Origin.ActorLocation - ActorLocation).SafeNormal;
		SetActorRotation(FQuat::MakeFromZ(Direction));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DistanceTraveled += Speed * DeltaSeconds;
		Speed += Acceleration * DeltaSeconds;

		if (DistanceTraveled > MaxTravelDistance)
			DestroyActor();			

		AddActorWorldOffset(Direction * Speed * DeltaSeconds);
	}
}