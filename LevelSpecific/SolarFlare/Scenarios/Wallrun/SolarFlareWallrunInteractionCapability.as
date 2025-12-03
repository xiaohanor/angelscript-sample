class USolarFlareWallrunInteractionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SolarFlareWallrunInteractionCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerTargetablesComponent PlayerTargetablesComponent;

	float InteractionDuration = 1.0;
	float InteractionDeactivateTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsBlocked() && !IsActive())
			PlayerTargetablesComponent.ShowWidgetsForTargetables(USolarFlareTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSolarFlareTargetableParams& Params) const
	{
		if (!WasActionStarted(ActionNames::Interaction))
			return false;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(USolarFlareTargetableComponent);
		if (PrimaryTarget == nullptr)
			return false;

		Params.ActivatedTargetable = PrimaryTarget;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds >  InteractionDeactivateTime)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSolarFlareTargetableParams Params)
	{
		ASolarFlareWallrunInteraction Interaction = Cast<ASolarFlareWallrunInteraction>(Params.ActivatedTargetable.Owner);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Interaction);
		InteractionDeactivateTime = Time::GameTimeSeconds + InteractionDuration;
		Interaction.ActivateTargetableAction();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}