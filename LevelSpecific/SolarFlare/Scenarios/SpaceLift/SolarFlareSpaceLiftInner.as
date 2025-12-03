struct FSolarFlareSpaceLiftSequenceGroups
{
	UPROPERTY(EditAnywhere)
	TArray<AHazeLevelSequenceActor> Sequences;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareCoverVolumeActor> EnableCoverVolumes;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareCoverVolumeActor> DisableCoverVolumes;

	void PlaySequences()
	{
		for (AHazeLevelSequenceActor Seq : Sequences)
			Seq.PlayLevelSequenceSimple(FOnHazeSequenceFinished());
	}

	void DisableAllCovers(FInstigator Disabler) const
	{
		for (ASolarFlareCoverVolumeActor Cover : EnableCoverVolumes)
		{
			if (!Cover.HasDisabler(Disabler))
				Cover.AddDisabler(Disabler);
		}
		
		for (ASolarFlareCoverVolumeActor Cover : DisableCoverVolumes)
		{
			if (!Cover.HasDisabler(Disabler))
				Cover.AddDisabler(Disabler);
		}
	}

	void SwitchCovers(FInstigator Switcher) const
	{
		for (ASolarFlareCoverVolumeActor Cover : EnableCoverVolumes)
		{
			Cover.RemoveDisabler(Switcher);
		}
		
		for (ASolarFlareCoverVolumeActor Cover : DisableCoverVolumes)
		{
			Cover.AddDisabler(Switcher);
		}		
	}
}

class ASolarFlareSpaceLiftInner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachToParentComp;

	UPROPERTY(EditAnywhere)
	TArray<FSolarFlareSpaceLiftSequenceGroups> SequenceGroups;

	UPROPERTY(EditAnywhere)
	float TravelSpeed = 5000.0;

	UPROPERTY(EditAnywhere)
	ASolarFlareSun Sun;

	int Index = 0;

	bool bCanRunDestruction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (FSolarFlareSpaceLiftSequenceGroups& Group : SequenceGroups)
			Group.DisableAllCovers(this);

		for (ASolarFlareCoverVolumeActor Cover : SequenceGroups[0].DisableCoverVolumes)
		{
			Cover.RemoveDisabler(this);
		}		

		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (!bCanRunDestruction)
			return;
		
		if (Index < SequenceGroups.Num())
		{
			SequenceGroups[Index].PlaySequences();
			Timer::SetTimer(this, n"DelayedSwitchCovers", Sun.FireDuration);
		}
	}

	UFUNCTION()
	void DelayedSwitchCovers()
	{
		SequenceGroups[Index].SwitchCovers(this);
		Index++;
	}

	UFUNCTION()
	void EnableSpaceLiftDestructionEvents()
	{
		Index = 0;
		bCanRunDestruction = true;
	}
}	