class USummitEggPlacedCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;
	
	AHazePlayerCharacter Player;

	ASummitEggBackpack Backpack;
	USummitEggBackpackComponent BackpackComp;

	ASummitEggHolder EggPlacementHolder;

	const float AnimationDurationBuffer = 0.05;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BackpackComp.bExternalPickupRequested)
			return true;

		if(EggPlacementHolder.bLockPlayerWhileInteracting)
		{
			if(WasActionStarted(ActionNames::Cancel))
				return true;
			
			else
				return false;
		}
		else if(BackpackComp.bPickupRequested)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EggPlacementHolder = BackpackComp.CurrentEggHolder.Value;
		if(EggPlacementHolder.bLockPlayerWhileInteracting)
		{
			Backpack.PlaySlotAnimation(BackpackComp.BackpackMhAnim);
			Player.PlaySlotAnimation(BackpackComp.PlayerMhAnim);
			BackpackComp.BlockPlayer();
			Player.ShowCancelPrompt(EggPath::EggPlaceCancelPromptInstigator);
		}

		BackpackComp.DetachEgg(EggPlacementHolder);
		if (HasControl())
			BackpackComp.NetActivateHolder(EggPlacementHolder);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(EggPlacementHolder.bLockPlayerWhileInteracting)
		{
			BackpackComp.UnblockPlayer();
		}
		Player.RemoveCancelPromptByInstigator(EggPath::EggPlaceCancelPromptInstigator);
		BackpackComp.bExternalPickupRequested = false;
	}
}