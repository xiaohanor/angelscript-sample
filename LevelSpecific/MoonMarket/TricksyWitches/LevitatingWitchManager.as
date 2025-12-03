class ALevitatingWitchManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	TArray<ALevitatingWitch> Witches;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
		{
			auto Lantern = Cast<ALevitatingWitch>(Actor);
			if (Lantern != nullptr)
				Witches.Add(Lantern);
		}

		if (bStartDisabled)
		{
			for (ALevitatingWitch Witch : Witches)
			{
				Witch.AddActorDisable(this);
			}
		}
	}

	UFUNCTION()
	void EnableWitches()
	{
		for (ALevitatingWitch Witch : Witches)
		{
			Witch.RemoveActorDisable(this);
		}
	}

	UFUNCTION()
	void DisableWitches()
	{
		for (ALevitatingWitch Witch : Witches)
		{
			Witch.AddActorDisable(this);
		}		
	}
};