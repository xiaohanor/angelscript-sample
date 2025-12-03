class UMagnetAnnoyingDroneIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 120;

	AMagnetAnnoyingDrone AnnoyingDrone;

	const float MoveSpeed = 500;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AnnoyingDrone = Cast<AMagnetAnnoyingDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AnnoyingDrone.State != EMagnetAnnoyingDroneState::Idle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AnnoyingDrone.State != EMagnetAnnoyingDroneState::Idle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(AnnoyingDrone.SplinePosition.IsForwardOnSpline())
			AnnoyingDrone.SplinePosition.ReverseFacing();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnnoyingDrone.GrabAlpha = 0;

		float RemainingDistance;
		AnnoyingDrone.SplinePosition.Move(MoveSpeed * DeltaTime, RemainingDistance);

		AnnoyingDrone.ApplySplinePosition(DeltaTime);
	}
};