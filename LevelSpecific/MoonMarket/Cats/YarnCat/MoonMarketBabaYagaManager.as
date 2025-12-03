class AMoonMarketBabaYagaManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY()
	TArray<AActor> BabaYagaActors;

	TArray<AMoonMarketBabaYagaGeoManager> GeoManagers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAttachedActors(BabaYagaActors);
		for (AActor Actor : BabaYagaActors)
		{
			Actor.AddActorDisable(this);
		}
	}

	UFUNCTION()
	void FindGeoManagers()
	{
		GeoManagers = TListedActors<AMoonMarketBabaYagaGeoManager>().GetArray();
	}

	UFUNCTION()
	void EnableBabaYagaActors()
	{
		for (AActor Actor : BabaYagaActors)
		{
			Actor.RemoveActorDisable(this);
		}
	}
};