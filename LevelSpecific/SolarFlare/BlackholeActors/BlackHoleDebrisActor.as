class ABlackHoleDebrisActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot, ShowOnActor)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	float RotationSpeedMultiplier = 1.0;

	bool bIsPulling;

	FVector Direction;
	FVector TargetLoc;

	float MaxPullSpeed = 11000.0;
	float CurrentPullSpeed;

	FRotator RandomRotationAmount;
	float RandomRotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		CurrentPullSpeed = MaxPullSpeed / 2.0;

		RandomRotationSpeed = Math::RandRange(90, 270);
		RandomRotationAmount = FRotator(Math::RandRange(0.5, 1), Math::RandRange(0.5, 1), Math::RandRange(0.5, 1));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentPullSpeed = Math::FInterpConstantTo(CurrentPullSpeed, MaxPullSpeed, DeltaSeconds, MaxPullSpeed / 2.0);
		ActorLocation += Direction * CurrentPullSpeed * DeltaSeconds; 
		ActorRotation += RandomRotationAmount * (RandomRotationSpeed * RotationSpeedMultiplier) * DeltaSeconds;

		if ((TargetLoc - ActorLocation).Size() < CurrentPullSpeed * DeltaSeconds)
		{
			AddActorDisable(this);
		}
	}

	void ActivateBlackolePull(FVector NewTargetLocation)
	{
		TargetLoc = NewTargetLocation;
		SetActorTickEnabled(true);
		Direction = (NewTargetLocation - ActorLocation).GetSafeNormal();
		bIsPulling = true;
	}
};