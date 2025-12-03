class USkippingStonesPickupCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	USkippingStonesPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;

	float PickupTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Pickup)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Pickup)
			return true;

		if(PlayerComp.IsHoldingStone() && Time::GetGameTimeSince(PickupTime) > SkippingStones::PickupEndDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.State = ESkippingStonesState::Aim;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && PlayerComp.HeldSkippingStone == nullptr && PlayerComp.bShouldPickUpStone)
		{
			CrumbPickupStone();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPickupStone()
	{
		Player.PlayForceFeedback(PlayerComp.PickupFeedback, false, true, this);
		PlayerComp.PickupStone();
		PickupTime = Time::GameTimeSeconds;
	}
};