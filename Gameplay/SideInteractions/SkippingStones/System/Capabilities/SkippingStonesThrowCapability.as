class USkippingStonesThrowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 120;

	USkippingStonesPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;

	float ThrowTime = 0;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Throw)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Throw)
			return true;

		if (!PlayerComp.IsHoldingStone() && Time::GetGameTimeSince(ThrowTime) > SkippingStones::ThrowEndDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlayForceFeedback(PlayerComp.PickupFeedback, false, true, this, 4 * Math::Max(PlayerComp.ChargeAlpha, 0.05));
		PlayerComp.State = ESkippingStonesState::Throw;
		Player.SetAnimTrigger(n"Throw");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.State = ESkippingStonesState::Pickup;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && PlayerComp.IsHoldingStone() && PlayerComp.bShouldThrowStone)
		{
			PlayerComp.ThrowStone();
			ThrowTime = Time::GameTimeSeconds;
		}
	}
};