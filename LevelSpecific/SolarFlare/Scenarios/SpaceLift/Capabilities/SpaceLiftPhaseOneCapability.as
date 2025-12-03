class USpaceLiftPhaseOneCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASolarFlareSpaceLiftMain SpaceLiftMain;
	ASolarFlareSun Sun;

	TArray<ASolarFlareSpaceLiftOuterCover> OuterCoversStage1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceLiftMain = Cast<ASolarFlareSpaceLiftMain>(Owner);
		Sun = TListedActors<ASolarFlareSun>().GetSingle();
	
	
		OuterCoversStage1 = SpaceLiftMain.OuterCoversStage1;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return false;

		if (!SolarFlareSpaceLiftData::IsStageApplicable(1, SpaceLiftMain.CurrentHits))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpaceLiftMain.bLiftActive)
			return true;
		
		if (!SolarFlareSpaceLiftData::IsStageApplicable(1, SpaceLiftMain.CurrentHits))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpaceLiftMain.ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
		Sun.SetWaitDuration(3.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpaceLiftMain.ReactionComp.OnSolarFlareImpact.Unbind(this, n"OnSolarFlareImpact");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.SetStickyRespawnPoint(SpaceLiftMain.RespawnPoint1);

		TArray<ASolarFlareSpaceLiftOuterCover> RemoveCovers;

		for (ASolarFlareSpaceLiftOuterCover Cover : OuterCoversStage1)
		{
			if (Cover.IsCoveringPlayer())
			{
				RemoveCovers.Add(Cover);
			}
		}

		if (RemoveCovers.Num() == 0)
		{
			for (int i = 0; i < 2; i++)
			{
				int RIndex = Math::RandRange(0, OuterCoversStage1.Num() - 1);
				OuterCoversStage1[RIndex].ActivateDestruction();
				OuterCoversStage1.Remove(OuterCoversStage1[RIndex]);			
			}
		}
		else
		{
			for (ASolarFlareSpaceLiftOuterCover Cover : RemoveCovers)
				OuterCoversStage1.Remove(Cover);

			if (RemoveCovers.Num() == 1)
			{
				int RIndex = Math::RandRange(0, RemoveCovers.Num() - 1);
				RemoveCovers.Add(OuterCoversStage1[RIndex]);
				OuterCoversStage1.Remove(RemoveCovers[1]);
			}

			for (ASolarFlareSpaceLiftOuterCover Cover : RemoveCovers)
				Cover.ActivateDestruction();
		}
	}
};