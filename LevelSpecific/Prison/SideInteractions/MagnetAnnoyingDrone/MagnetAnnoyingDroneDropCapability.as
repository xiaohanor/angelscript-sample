class UMagnetAnnoyingDroneDropCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AMagnetAnnoyingDrone AnnoyingDrone;

	const float OpenArmsTime = 0.5;
	const float WaitTime = 2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AnnoyingDrone = Cast<AMagnetAnnoyingDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AnnoyingDrone.State != EMagnetAnnoyingDroneState::Drop)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > WaitTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AnnoyingDrone.MagneticSocketComp.ForceDetachJumpMagnetDrone();

		AnnoyingDrone.MagneticSocketComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnnoyingDrone.State = EMagnetAnnoyingDroneState::Idle;

		AnnoyingDrone.MagneticSocketComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnnoyingDrone.GrabAlpha = Math::Saturate(ActiveDuration / OpenArmsTime);

		AnnoyingDrone.ApplySplinePosition(DeltaTime);
	}
};