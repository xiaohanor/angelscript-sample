class UMoonMarketBalloonCandyInteractionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerInteractionsComponent InteractionComp;
	UMoonMarketBalloonPotionComponent CandyComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionComp = UPlayerInteractionsComponent::Get(Player);
		CandyComp = UMoonMarketBalloonPotionComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > CandyComp.InteractionAnimation.PlayLength)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"PolymorphPotion", this);

		Player.PlaySlotAnimation(CandyComp.InteractionAnimation);
		CandyComp.ShapeshiftComponent.bIsShapeshifting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player.StopSlotAnimation();

		CandyComp.ShapeshiftComponent.bIsShapeshifting = false;

		if(InteractionComp.ActiveInteraction == nullptr)
			return;

		auto Candy = Cast<AMoonMarketBalloonCandy>(InteractionComp.ActiveInteraction.Owner);

		CandyComp.BeginInteraction(Candy);

		InteractionComp.ActiveInteraction.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};