class UMagnetAnnoyingDroneWaitForDropCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 105;

	AMagnetAnnoyingDrone AnnoyingDrone;

	const float DropDelay = 1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AnnoyingDrone = Cast<AMagnetAnnoyingDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AnnoyingDrone.State != EMagnetAnnoyingDroneState::WaitForDrop)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > DropDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnnoyingDrone.State = EMagnetAnnoyingDroneState::Drop;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnnoyingDrone.ApplySplinePosition(DeltaTime);
	}
};