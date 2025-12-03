class ASanctuaryWeeperRisingBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASanctuaryLightOrb Orb;

	UPROPERTY(EditAnywhere)
	float RiseSpeed = 1000;
	UPROPERTY(EditAnywhere)
	float HeightOffset = -5000;

	float Delay;
	float DelayTimer;

	float TargetHeight;
	float TimeAtActivation;

	bool bIsOrbActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Orb.OnActivated.AddUFunction(this, n"OnActivated");
		Orb.OnDeactivated.AddUFunction(this, n"OnDeactivated");

		float Distance = (Orb.ActorLocation - ActorLocation).Size();

		Delay = Distance * 0.001;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MeshRoot.WorldLocation.Z == TargetHeight)
			return;

		if(bIsOrbActivated)
		{
			
			if(DelayTimer < Delay)
			{
				DelayTimer += DeltaSeconds;
				return;
			}

		}
		else
		{
			DelayTimer -= DeltaSeconds;

			if(DelayTimer > 0)
				return;
		}	

		MeshRoot.WorldLocation =  Math::VInterpConstantTo(MeshRoot.WorldLocation, FVector(MeshRoot.WorldLocation.X, MeshRoot.WorldLocation.Y, TargetHeight), DeltaSeconds, RiseSpeed);


	}


	UFUNCTION()
	private void OnActivated()
	{
		TargetHeight = 0;

		bIsOrbActivated = true;
	}

	UFUNCTION()
	private void OnDeactivated()
	{
		TargetHeight = HeightOffset;

		bIsOrbActivated = false;
	}



};