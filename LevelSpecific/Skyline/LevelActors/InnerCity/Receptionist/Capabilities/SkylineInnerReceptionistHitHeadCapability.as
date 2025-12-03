class USkylineInnerReceptionistHitHeadCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 90;

	ASkylineInnerReceptionistBot Receptionist;
	int LastHitTimes = 0;

	FHazeAcceleratedRotator AccRot;
	FRotator OuchRot;
	FRotator OGRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (Receptionist.HitTimes != LastHitTimes)
			return false;
		if (Receptionist.HitTimes == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Receptionist.HitTimes != LastHitTimes)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastHitTimes = Receptionist.HitTimes;
		AccRot.SnapTo(Receptionist.HeadMesh.WorldRotation);
		OuchRot = Receptionist.HeadMesh.WorldRotation;
		OGRot = Receptionist.HeadMesh.WorldRotation;

		FVector RelativeImpact = Receptionist.LastHitData.ImpactPoint - Game::Mio.ActorCenterLocation;
		bool bRightSwing = Game::Mio.ActorRightVector.DotProduct(RelativeImpact) > 0.0;
		float ExtraRot = 40.0;
		ExtraRot *= bRightSwing ? 1.0 : -1.0;
		OuchRot.Yaw += ExtraRot;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Receptionist.HitTimes == 0)
			LastHitTimes = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < 0.7)
			AccRot.SpringTo(OuchRot, 50.0, 0.9, DeltaTime);
		else
			AccRot.AccelerateTo(OGRot, 0.8, DeltaTime);
		Receptionist.SyncedHeadLookDirection.SetValue(AccRot.Value.ForwardVector);
	}
};