class USummitEggPickUpCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default DebugCategory = SummitDebugCapabilityTags::EggBackpack;

	AHazePlayerCharacter Player;

	ASummitEggBackpack Backpack;
	USummitEggBackpackComponent BackpackComp;

	ASummitEggHolder EggPlacementHolder;

	const float AnimationDurationBuffer = 0.05;
	const float AnimNotifyInputSizeThreshold = 0.2;
	const float PickupEggRumbleDurationSubtraction = 0.3;

	float PickupAnimLength;

	bool bAnimNotifyHasUnblockedPlayer = false;
	bool bPickupRumblePlayed = false;

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
		if(ActiveDuration >= (PickupAnimLength - AnimationDurationBuffer))
			return true;

		if(BackpackComp.bResetRequested)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BackpackComp.AttachEgg();

		EggPlacementHolder = BackpackComp.CurrentEggHolder.Value;

		if(EggPlacementHolder.bFastAnimation)
		{
			PickupAnimLength = BackpackComp.FastBackpackPickupAnim.PlayLength;
			Backpack.PlaySlotAnimation(BackpackComp.FastBackpackPickupAnim);
			Player.PlaySlotAnimation(BackpackComp.FastPlayerPickupAnim);
		}
		else
		{
			PickupAnimLength = BackpackComp.PlayerPickupAnim.PlayLength;
			Backpack.PlaySlotAnimation(BackpackComp.BackpackPickupAnim);
			Player.PlaySlotAnimation(BackpackComp.PlayerPickupAnim);
		}

		BackpackComp.BlockPlayer();

		bAnimNotifyHasUnblockedPlayer = false;
		bPickupRumblePlayed = false;

		if (HasControl())
			BackpackComp.NetDeactivateHolder(EggPlacementHolder);

		Timer::SetTimer(this, n"DelayedRumble", 0.1, false);
	}

	UFUNCTION()
	private void DelayedRumble()
	{
		Player.PlayForceFeedback(BackpackComp.EggPlacedInBackpackRumble, false, false, this, 0.75);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bAnimNotifyHasUnblockedPlayer)
			BackpackComp.UnblockPlayer();

		BackpackComp.bPickupRequested = false;
		BackpackComp.CurrentEggHolder.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if(BackpackComp.bPlayerAnimUnblockRequested
			&& !MovementRaw.IsNearlyZero(AnimNotifyInputSizeThreshold))
			{
				CrumbAnimNotifyUnblockPlayer();
			}

		}
		if(!bPickupRumblePlayed
		&& ActiveDuration > PickupAnimLength - PickupEggRumbleDurationSubtraction)
		{
			Player.PlayForceFeedback(BackpackComp.EggPlacedInBackpackRumble, false, true, this);
			bPickupRumblePlayed = true;
		}
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbAnimNotifyUnblockPlayer()
	{
		Player.StopSlotAnimation();
		BackpackComp.UnblockPlayer();
		bAnimNotifyHasUnblockedPlayer = true;
		BackpackComp.bPlayerAnimUnblockRequested = false;
	}
}