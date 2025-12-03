class UMagnetHarpoonEnableMagnetsCapability : UHazeCapability
{
	// Does not need networking, as the state is already networked
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AMagnetHarpoon MagnetHarpoon;
	TArray<UMagnetDroneAutoAimComponent> MagnetAutoAimComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		MagnetHarpoon.GetComponentsByClass(UMagnetDroneAutoAimComponent, MagnetAutoAimComponents);

		// Disable all magnets by default
		for (auto MagnetAutoAimComponent : MagnetAutoAimComponents)
			MagnetAutoAimComponent.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MagnetHarpoon.State != EMagnetHarpoonState::Attached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MagnetHarpoon.State != EMagnetHarpoonState::Attached)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto MagnetAutoAimComponent : MagnetAutoAimComponents)
			MagnetAutoAimComponent.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto MagnetDrone = Drone::MagnetDronePlayer;

		// Detach magnet drone
		auto MagnetAttachedComp = UMagnetDroneAttachedComponent::Get(MagnetDrone);
		if (MagnetAttachedComp.IsAttachedToActor(MagnetHarpoon))
		{
			MagnetAttachedComp.Detach(n"MagnetHarpoon_Retracting");
			MagnetDrone.AddMovementImpulse(MagnetDrone.MovementWorldUp * 800.0);
		}

		for (auto MagnetAutoAimComponent : MagnetAutoAimComponents)
			MagnetAutoAimComponent.Disable(this);
	}
};