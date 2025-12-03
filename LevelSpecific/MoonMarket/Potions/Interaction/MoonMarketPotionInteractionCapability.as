class UMoonMarketPotionInteractionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerInteractionsComponent InteractionComp;
	UMoonMarketPotionInteractionComponent PotionComp;
	UHazeMovementComponent MoveComp;

	bool bPotionAttached = false;
	bool bDrinkingStarted = false;
	AMoonMarketPotion Potion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractionComp = UPlayerInteractionsComponent::Get(Player);
		PotionComp = UMoonMarketPotionInteractionComponent::Get(Player);
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
		if(ActiveDuration > PotionComp.InteractionAnimation.PlayLength)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDrinkingStarted = false;
		bPotionAttached = false;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Potion = Cast<AMoonMarketPotion>(InteractionComp.ActiveInteraction.Owner);
		Player.PlaySlotAnimation(PotionComp.InteractionAnimation);
		PotionComp.ShapeshiftComponent.bIsShapeshifting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player.StopSlotAnimation();

		PotionComp.ShapeshiftComponent.bIsShapeshifting = false;

		Potion.EmptyPotion();
		Potion.StopInteraction(Player);
		Potion.DetachFromActor();
		Potion.SetActorLocationAndRotation(Potion.OriginalLocation, Potion.OriginalRotation);

		if(InteractionComp.ActiveInteraction == nullptr)
			return;

		PotionComp.BeginInteraction(Potion);
		InteractionComp.ActiveInteraction.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 0.5 && !bPotionAttached)
		{
			bPotionAttached = true;
			Potion.AttachToActor(Player, n"RightAttach", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}

		if(ActiveDuration > 1.3 && !bDrinkingStarted)
		{
			bDrinkingStarted = true;
			Potion.StartDrinkingPotion();
		}
	}
};