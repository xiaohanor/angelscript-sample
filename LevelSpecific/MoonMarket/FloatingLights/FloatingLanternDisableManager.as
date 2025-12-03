class AFloatingLanternDisableManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = true;

	TArray<AFloatingLanterns> Lanterns;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
		{
			auto Lantern = Cast<AFloatingLanterns>(Actor);
			if (Lantern != nullptr)
				Lanterns.Add(Lantern);
		}

		if (bStartDisabled)
		{
			for (AFloatingLanterns Lantern : Lanterns)
			{
				Lantern.AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	void EnableLanterns()
	{
		for (AFloatingLanterns Lantern : Lanterns)
		{
			Lantern.RemoveActorDisable(this);
		}
	}

	UFUNCTION()
	void DisableLanterns()
	{
		for (AFloatingLanterns Lantern : Lanterns)
		{
			Lantern.AddActorDisable(this);
		}		
	}
};