class UMagnetAnnoyingDroneGrabCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	AMagnetAnnoyingDrone AnnoyingDrone;

	const float MoveSpeed = 1000;

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
		
		if(AnnoyingDrone.AttachedPlayer == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AnnoyingDrone.SplinePosition.IsAtEnd())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AnnoyingDrone.State = EMagnetAnnoyingDroneState::Grab;

		if(!AnnoyingDrone.SplinePosition.IsForwardOnSpline())
			AnnoyingDrone.SplinePosition.ReverseFacing();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnnoyingDrone.State = EMagnetAnnoyingDroneState::WaitForDrop;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnnoyingDrone.GrabAlpha = Math::FInterpConstantTo(AnnoyingDrone.GrabAlpha, 1, DeltaTime, 10);

		float RemainingDistance;
		AnnoyingDrone.SplinePosition.Move(MoveSpeed * DeltaTime, RemainingDistance);

		AnnoyingDrone.ApplySplinePosition(DeltaTime);
	}
};