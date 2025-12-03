class ASerpentHomingMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SerpentHomingMissileCapability");

	AHazePlayerCharacter TargetPlayer;

	float TargetSpeed = 4500.0;
	float Speed;
	float Acceleration = 8000.0;

	float LifeTime = 6.0;

	FVector Direction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Direction = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();

		FVector OffsetDirection;
		FVector RandomRight = ActorRightVector * Math::RandRange(-1.0, 1.0);
		FVector RandomUp = ActorUpVector * Math::RandRange(-1.0, 1.0);
		OffsetDirection += RandomRight;
		OffsetDirection += RandomUp;

		ActorRotation = Direction.Rotation();

		Direction += OffsetDirection;
		Direction.Normalize(); 

		LifeTime += Time::GameTimeSeconds;
	}
};