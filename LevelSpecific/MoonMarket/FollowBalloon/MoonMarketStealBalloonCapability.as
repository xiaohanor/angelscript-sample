class UMoonMarketStealBalloonCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerTargetablesComponent TargetableComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetableComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto BalloonTargetable = TargetableComponent.GetPrimaryTarget(UMoonMarketStealBalloonTargetableComp);
		if(BalloonTargetable == nullptr)
			return false;

		if(!WasActionStarted(ActionNames::Interaction))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto OtherPlayerBalloonComp = UMoonMarketHoldBalloonComp::Get(Game::GetOtherPlayer(Player.Player));
		UMoonMarketHoldBalloonComp::Get(Player).StealOtherPlayerBalloons(OtherPlayerBalloonComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TargetableComponent.ShowWidgetsForTargetables(UMoonMarketStealBalloonTargetableComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};