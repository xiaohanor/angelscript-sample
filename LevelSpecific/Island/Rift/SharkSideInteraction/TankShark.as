class ATankShark : AKineticSplineFollowActor
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SharkMesh;

	bool bHasSmashedGlass;
	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ASpotSound> WaterLeakSpotSound;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnReachedEnd.AddUFunction(this, n"SharkSmashGlass");
	}

	UFUNCTION()
	void StartShark()
	{
		ActivateFollowSpline();
		UIsland_Rift_TankSharkEffectHandler::Trigger_SharkStart(this);
	}

	UFUNCTION()
	void SharkSmashGlass()
	{
		if(bHasSmashedGlass)
		{
			AddActorDisable(this);
			return;
		}

		UIsland_Rift_TankSharkEffectHandler::Trigger_SharkHitTheGlass(this);
		bHasSmashedGlass = true;

		auto WaterLeakSpot = WaterLeakSpotSound.Get();
		if(WaterLeakSpot != nullptr)
		{
			auto SpotSound = Cast<USpotSoundComponent>(WaterLeakSpot.SpotSoundComponent);
			SpotSound.Start();
		}
	}
}