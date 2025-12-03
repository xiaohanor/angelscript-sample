class ASummitWaterTempleInnerWaterBobbingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent StaticMeshComponent;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Rate = 0.15;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float Offset = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveMax = 100.0;

	UPROPERTY(EditAnywhere, Category=  "Settings")
	FVector Axis = FVector(0, 0, 1.0);

	FVector StartLocation;
	FVector PreviousLocation;

	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		PreviousLocation = StartLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector SinOffset = Axis * MoveMax * Math::Sin((Time::GlobalCrumbTrailTime + (Offset / Rate)) * Rate * TWO_PI);
		ActorLocation = StartLocation + SinOffset;
		
		FVector MovedVelocity = (ActorLocation - PreviousLocation) / DeltaSeconds;
		
		if(bIsMoving)
		{
			if(MovedVelocity.IsNearlyZero(20.0))
			{
				if(MovedVelocity.Z > 0)
					USummitWaterTempleInnerWaterBobbingPlatformEventHandler::Trigger_OnStoppedMovingUp(this);
				else
					USummitWaterTempleInnerWaterBobbingPlatformEventHandler::Trigger_OnStoppedMovingDown(this);
				bIsMoving = false;
			}
		}
		else
		{
			if(!MovedVelocity.IsNearlyZero(20.0))
			{
				if(MovedVelocity.Z > 0)
					USummitWaterTempleInnerWaterBobbingPlatformEventHandler::Trigger_OnStartedMovingUp(this);
				else
					USummitWaterTempleInnerWaterBobbingPlatformEventHandler::Trigger_OnStartedMovingDown(this);
				bIsMoving = true;
			}
		}

		PreviousLocation = ActorLocation;
	}
};