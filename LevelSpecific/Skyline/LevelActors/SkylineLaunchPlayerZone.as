class ASkylineLaunchPlayerZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(50.0, 50.0, 50.0,);
	

	
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	float JumpHeight = 2000.0;

	UPROPERTY(EditAnywhere)
	float Cooldown = 1.0;

	UPROPERTY(EditAnywhere)
	AActor TargetPoint;

	bool bHasLaunched = false;
	float ActivationTime = 0.0;

	UPROPERTY(EditAnywhere)
	bool bCanZoeUse = true;

	UPROPERTY(EditAnywhere)
	bool bCanMioUse = true;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		
		auto Trace = Trace::InitFromPrimitiveComponent(Trigger);
		auto Overlaps = Trace.QueryOverlaps(Trigger.WorldLocation);

		

		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
			{
				if((Player==Game::Mio && !bCanMioUse) || (Player==Game::Zoe && !bCanZoeUse))
				{
					continue;
				}
				auto LaunchComp = USkylineLaunchPadUserComponent::Get(Player);
				FVector TargetLocationWorld = ActorTransform.TransformPositionNoScale(TargetLocation);

				if (TargetPoint != nullptr)
					TargetLocationWorld = TargetPoint.ActorLocation;

				LaunchComp.Launch(TargetLocationWorld, JumpHeight);
//				Debug::DrawDebugPoint(TargetLocationWorld, 100.0, FLinearColor::Green, 5.0);
			}
		}
	
		ActivationTime = Time::GameTimeSeconds;
		bHasLaunched = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHasLaunched && Time::GameTimeSeconds > ActivationTime + Cooldown)
		{
			bHasLaunched = false;
		}
	}




	
};