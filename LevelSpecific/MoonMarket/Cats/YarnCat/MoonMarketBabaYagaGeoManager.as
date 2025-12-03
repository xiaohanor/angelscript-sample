class AMoonMarketBabaYagaGeoManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	UPROPERTY()
	TArray<AActor> BabaYagaActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAttachedActors(BabaYagaActors);

		if (bStartDisabled)
		{
			DisableBabaYagaGeoActors();
		}
	}

	UFUNCTION()
	void ActivateSwitchGeoActors()
	{
		
	}

	UFUNCTION()
	void EnableBabaYagaGeoActors()
	{
		for (AActor Actor : BabaYagaActors)
		{
			Actor.RemoveActorDisable(this);
		}
	}
	
	UFUNCTION()
	void DisableBabaYagaGeoActors()
	{
		for (AActor Actor : BabaYagaActors)
		{
			Actor.AddActorDisable(this);
		}
	}
};