class UMimicChestKickedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMimic Mimic;

	bool bHasBeenEnabled = false;
	bool bHasBeenDisabled = false;

	float MaxPitch = 60.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mimic = Cast<AMoonMarketMimic>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Mimic.bWasKicked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= MimicChest::TotalKickTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasBeenEnabled = false;
		bHasBeenDisabled = false;
		Mimic.KickInteractComp.Disable(this);
		UMoonMarketCatEventHandler::Trigger_OnMimicLidOpen(Mimic.Cat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mimic.KickInteractComp.Enable(this);
		Mimic.bWasKicked = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > MimicChest::MinKickTime && !bHasBeenEnabled)
		{
			Mimic.Cat.InteractComp.Enable(Mimic);
			bHasBeenEnabled = true;
		}

		if (ActiveDuration > MimicChest::MaxKickTime && !bHasBeenDisabled)
		{
			bHasBeenDisabled = true;
			Mimic.Cat.InteractComp.Disable(Mimic);
			UMoonMarketCatEventHandler::Trigger_OnMimicLidClosed(Mimic.Cat);
		}
	}
};