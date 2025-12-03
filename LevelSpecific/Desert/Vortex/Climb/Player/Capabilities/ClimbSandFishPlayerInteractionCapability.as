class UClimbSandFishPlayerInteractionCapability : UInteractionCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;

	AVortexSandFish SandFish;
	UClimbSandFishPlayerComponent PlayerComp;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return false;

		if (!CheckInteraction.Owner.IsA(AVortexSandFish))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		SandFish = Cast<AVortexSandFish>(Params.Interaction.Owner);
		PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
		PlayerComp.InteractionComp = Cast<USteerSandFishInteractionComponent>(Params.Interaction);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetActorLocationAndRotation(PlayerComp.InteractionComp.WorldLocation, PlayerComp.InteractionComp.ComponentQuat);
	}
};