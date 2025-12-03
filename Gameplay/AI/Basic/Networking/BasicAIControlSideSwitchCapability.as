struct FAIControlSideSwitchParameters
{
	AActor Controller;
	FVector Location;
	FRotator Rotation;
}

// Will only switch control side when allowed to by other capabilities 
class UBasicAIControlSideSwitchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::ControlSideSwitch);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIControlSideSwitchComponent ControlSwitchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ControlSwitchComp = UBasicAIControlSideSwitchComponent::GetOrCreate(Owner);
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		ControlSwitchComp.Clear();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAIControlSideSwitchParameters& OutParams) const
	{
		if (ControlSwitchComp.WantedController == nullptr)
			return false;

		if (ControlSwitchComp.WantedController.HasControl() == HasControl())
			return false;

		OutParams.Controller = ControlSwitchComp.WantedController;	
		OutParams.Location = Owner.ActorLocation;
		OutParams.Rotation = Owner.ActorRotation;
		return true;
	}

	// Will run on the new control side
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAIControlSideSwitchParameters Params)
	{
		ControlSwitchComp.Clear();

		// Switch control side
		Owner.SetActorControlSide(Params.Controller);

		// Stop behaviour and movement until switch is complete
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);

		// Teleport to where actor was on the original control side, but smooth it over with mesh offset
		Owner.SmoothTeleportActor(Params.Location, Params.Rotation, this);

		// On new control side we can unblock capabilities immediately so there is no risk any other netmessages can occur in between block/unblock.
		if (Params.Controller.HasControl())
			UnblockCapabilities();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// On new remote side we need to wait for the other side to crumb deactivate before we clean up
		if (!HasControl())
			UnblockCapabilities();
	}

	void UnblockCapabilities()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
	}
};

