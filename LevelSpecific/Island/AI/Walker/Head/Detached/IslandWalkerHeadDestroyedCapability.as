class UIslandWalkerHeadDestroyedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"HurtReaction");
	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandWalkerHeadComponent HeadComp;
	UBasicAIAnimationComponent AnimComp;
	UIslandWalkerHeadHatchInteractionComponent HatchInteraction;
	TArray<UPerchPointComponent> PerchPoints;
	UIslandWalkerSettings Settings;

	AIslandWalkerHeadStumpTarget Stump = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		HatchInteraction = UIslandWalkerHeadHatchInteractionComponent::Get(Owner);
		Owner.GetComponentsByClass(PerchPoints);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnSetupComplete");
	}

	UFUNCTION()
	private void OnSetupComplete(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Stump == nullptr)
			return false;
		if (!Stump.bStumpDestroyed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.HeadDestroyedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Detach any players tagging along
		HatchInteraction.Disable(this);
		for (UPerchPointComponent Perch : PerchPoints)
		{
			Perch.Disable(this);
		}
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerInteractionsComponent::Get(Player).KickPlayerOutOfInteraction(HatchInteraction);
		}

		HeadComp.State = EIslandWalkerHeadState::Destroyed;
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		UIslandWalkerPhaseComponent::Get(HeadComp.NeckCableOrigin.Owner).SetPhase(EIslandWalkerPhase::Destroyed);

		UIslandWalkerHeadEffectHandler::Trigger_OnStoppedFlying(Owner);		
		UIslandWalkerHeadEffectHandler::Trigger_OnDestruction(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.ClearFeature(this);
		
		Owner.AddActorDisable(this);
	}
};