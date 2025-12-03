class UIslandWalkerNeckPanelEnablingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandWalkerNeckRoot NeckRoot;
	bool bPanelDisabled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Keep active while shootable panel is exposed
		if (NeckRoot.NeckTarget == nullptr)
			return false;
		if (!NeckRoot.NeckTarget.bIsPoweredUp)
			return false;
		if (NeckRoot.NeckTarget.IsActorDisabled())
			return false;
		if (!NeckRoot.NeckTarget.bForceFieldBreached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!NeckRoot.NeckTarget.bIsPoweredUp)
			return true;
		if (NeckRoot.NeckTarget.IsActorDisabled())
			return true;
		if (NeckRoot.NeckTarget.ForceFieldComp.Integrity > 0.99)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bPanelDisabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bPanelDisabled)
		{
			NeckRoot.NeckTarget.ShootablePanel.TargetComp.Enable(this);
			bPanelDisabled = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter Shooter = (NeckRoot.ForceFieldType == EIslandForceFieldType::Red) ? Game::Zoe : Game::Mio;
		if (NeckRoot.NeckTarget.ShootablePanel.bIsDisabled)
		{
			if (Shooter.ActorLocation.Z > NeckRoot.WorldLocation.Z + 200.0)
				NeckRoot.NeckTarget.ShootablePanel.EnablePanel();
		}   
		else 
		{
			// Panel is currently enabled
			if (Shooter.ActorLocation.Z < NeckRoot.WorldLocation.Z) 
				NeckRoot.NeckTarget.ShootablePanel.DisablePanel();
		}

	}
};