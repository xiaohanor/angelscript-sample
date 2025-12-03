class ASkylineBossCarpetBomber : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBossCarpetBomb> BombClass;

	UPROPERTY(EditAnywhere)
	float Speed = 30000.0;

	UPROPERTY(EditAnywhere)
	float DropFrequency = 6.0;
	float DropTime = 0.0;

	bool bActiveBombRun = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActiveBombRun)
		{
			ActorLocation += ActorForwardVector * Speed * DeltaSeconds;	

			if (Time::GameTimeSeconds > DropTime && HasValidDropTarget())
				DropBomb();
		}
	}

	void BeginBombRun(AActor Target)
	{
		FVector Direction = (Target.ActorLocation - ActorLocation).SafeNormal;
		Direction = Direction.VectorPlaneProject(FVector::UpVector);
		SetActorRotation(FQuat::MakeFromZX(FVector::UpVector, Direction));
		RemoveActorDisable(this);
		bActiveBombRun = true;
	}

	bool HasValidDropTarget()
	{
		FVector Start = ActorLocation;
		FVector End = Start - FVector::UpVector * 50000.0;
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		auto HitResult = Trace.QueryTraceSingle(Start, End);

		return HitResult.bBlockingHit;
	}

	void DropBomb()
	{
		SpawnActor(BombClass, ActorLocation, ActorRotation);
		DropTime = Time::GameTimeSeconds + (1.0 / DropFrequency);
	}
};