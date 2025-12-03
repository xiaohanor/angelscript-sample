class UGiantHornInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AGiantHorn Horn;
	UPlayerTeenDragonComponent DragonComp;
	UInteractionComponent InteractionComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Horn = Cast<AGiantHorn>(Params.Interaction.Owner);

		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Horn.SetActorControlSide(Player);

		InteractionComp = Params.Interaction;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		InteractionComp.DisableForPlayer(Player, this);
		Timer::SetTimer(this, n"ReEnableInteraction", 0.5);
	}

	UFUNCTION()
	private void ReEnableInteraction()
	{
		InteractionComp.EnableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TempLog = TEMPORAL_LOG(Horn);
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Movement);

		if(Horn.bIsActive)
			TempLog.Status("Is Active", FLinearColor::Green);
		else
			TempLog.Status("Is NOT Active", FLinearColor::Red);

		if(Horn.bDoubleInteractCompleted)
			LeaveInteraction();
	}
};