class USanctuaryBossDisableInCutsceneCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	ASanctuaryBossArenaHydra HydraBoss;
	TArray<FVector> HydraLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HydraBoss == nullptr)
		{
			TListedActors<ASanctuaryBossArenaHydra> Hydras;
			if (Hydras.Num() > 0)
				HydraBoss = Hydras.Single;	
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HydraBoss == nullptr)
			return false;
		if (Player.bIsControlledByCutscene)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraBoss == nullptr)
				return false;
		if (!Player.bIsControlledByCutscene)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HydraBoss.BlockCapabilities(CapabilityTags::GameplayAction, this);
		for (int iHydra = 0; iHydra < HydraBoss.HydraHeads.Num(); ++iHydra)
		{
			ASanctuaryBossArenaHydraHead Head = HydraBoss.HydraHeads[iHydra];
			Head.BlockCapabilities(CapabilityTags::GameplayAction, this);
			HydraLocations.Add(Head.OriginalActorLocation);
			Head.bIsCutsceneDisabled = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraBoss.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		for (int iHydra = 0; iHydra < HydraBoss.HydraHeads.Num(); ++iHydra)
		{
			ASanctuaryBossArenaHydraHead Head = HydraBoss.HydraHeads[iHydra];
			Head.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			FHitResult Unused;
			if (Head.StartPosRef != nullptr)
				Head.SmoothTeleportActor(Head.StartPosRef.ActorLocation, Head.StartPosRef.ActorRotation, this, 0.5);
			else
				Head.SetActorLocation(HydraLocations[iHydra], false, Unused, true);
			Head.bIsCutsceneDisabled = false;
		}
	}
};