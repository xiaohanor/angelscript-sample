class USummitEggPlacingCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;

	AHazePlayerCharacter Player;

	ASummitEggBackpack Backpack;
	USummitEggBackpackComponent BackpackComp;

	ASummitEggHolder EggPlacementHolder;

	const float AnimationDurationBuffer = 0.05;

	float PlacingAnimLength;

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
		if(!BackpackComp.bPlacementRequested)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= (PlacingAnimLength - AnimationDurationBuffer))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BackpackComp.BlockPlayer();

		EggPlacementHolder = BackpackComp.CurrentEggHolder.Value;
		EggPlacementHolder.EggIsBeingPlaced[Player] = true;

		if(EggPlacementHolder.bFastAnimation)
		{
			PlacingAnimLength = BackpackComp.FastPlayerPlacingAnim.PlayLength;
			Backpack.PlaySlotAnimation(BackpackComp.FastBackpackPlacingAnim);
			Player.PlaySlotAnimation(BackpackComp.FastPlayerPlacingAnim);
		}
		else
		{
			PlacingAnimLength = BackpackComp.PlayerPlacingAnim.PlayLength;
			Backpack.PlaySlotAnimation(BackpackComp.BackpackPlacingAnim);
			Player.PlaySlotAnimation(BackpackComp.PlayerPlacingAnim);
		}

		BackpackComp.bPlacementRequested = false;
		Timer::SetTimer(this, n"DelayedRumble", 0.2, false);
	}

	UFUNCTION()
	private void DelayedRumble()
	{
		Player.PlayForceFeedback(BackpackComp.EggPlacedInBackpackRumble, false, false, this, 0.15);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BackpackComp.UnblockPlayer();
		EggPlacementHolder.EggIsBeingPlaced[Player] = false;
	}
}