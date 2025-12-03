enum ESewerWaterState
{
	Still,
	Pouring,
	Draining
}

class ASanctuarySewerWater : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaterRoot;

	UPROPERTY(DefaultComponent, Attach = WaterRoot)
	UStaticMeshComponent WaterMeshComp;
	default WaterMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UBillboardComponent MinLevelPoint;

	UPROPERTY(DefaultComponent)
	UBillboardComponent MaxLevelPoint;

	UPROPERTY(EditAnywhere)
	float WaterSpeed = 60;
	
	bool bIsRising = false;
	bool bIsDecending = false;

	UPROPERTY(EditAnywhere)
	ESewerWaterState WaterState;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> LightBirdCages;
	
	ADarkPortalActor DarkPortal;

	// UPROPERTY(EditAnywhere)
	// TArray<AActor> Actors;

	UPROPERTY(EditAnywhere)
	bool bWaterEnabled = false;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(AHazeActor BirdCage : LightBirdCages)
		{
			auto BirdResponseComp = ULightBirdResponseComponent::Get(BirdCage);

			if(BirdResponseComp == nullptr)
				return;

			BirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
			BirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
		}

		auto PortalUserComp = UDarkPortalUserComponent::Get(Game::Zoe);

		if(PortalUserComp != nullptr)
		{
			if(PortalUserComp.Portal!= nullptr)
				DarkPortal = PortalUserComp.Portal;
			
		}
		
	}

	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if(!bWaterEnabled)
			return;
		if(WaterState == ESewerWaterState::Pouring)
		{
			if(WaterRoot.RelativeLocation.Z < MaxLevelPoint.RelativeLocation.Z)
			{
				WaterRoot.RelativeLocation += ActorUpVector * WaterSpeed * DeltaSeconds;
				
			}


		}
		else if(WaterState == ESewerWaterState::Draining)
		{
			if(WaterRoot.RelativeLocation.Z > MinLevelPoint.RelativeLocation.Z)
			{
				WaterRoot.RelativeLocation -= ActorUpVector * WaterSpeed * DeltaSeconds;

			}
			
		}

		if(DarkPortal == nullptr)
		{
			auto PortalUserComp = UDarkPortalUserComponent::Get(Game::Zoe);
			if(PortalUserComp != nullptr)
			{
				DarkPortal = PortalUserComp.Portal;
			}
		}
		else
		{
			if(DarkPortal.IsSettled())
			{
				if(DarkPortal.ActorLocation.Z < WaterRoot.WorldLocation.Z)
					DarkPortal.RequestDespawn();
			}
		}

	}

	void WaterRise(float Speed)
	{
		WaterSpeed = Speed;
		WaterState = WaterState = ESewerWaterState::Pouring;
	}
	void WaterDrain(float Speed)
	{
		WaterSpeed = Speed;
		WaterState = WaterState = ESewerWaterState::Draining;
		PrintToScreen("Drain: " + WaterRoot.RelativeLocation.Z + " > " + MinLevelPoint.RelativeLocation.Z);


	}

	UFUNCTION()
	private void OnIlluminated()
	{
		WaterDrain(WaterSpeed);
	}

		UFUNCTION()
	private void OnUnilluminated()
	{
		WaterRise(WaterSpeed);
	}


};