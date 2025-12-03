class USkylineInnerReceptionistLookAtCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ReceptionistLook");
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 110;

	ASkylineInnerReceptionistBot Receptionist;

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
		if (Receptionist.HitOrDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Receptionist.HitOrDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DesiredLookDirection = Receptionist.GetDesiredLookDirection();
		bool bIsCorrectlyAligned = Math::DotToDegrees(Receptionist.HeadMesh.ForwardVector.DotProduct(DesiredLookDirection)) < 0.1;
		if (!bIsCorrectlyAligned)
		{
			float RotationSpeed = Receptionist.State == ESkylineInnerReceptionistBotState::Annoyed ? 90.0 : 40.0 ;
			FVector CappedTargetRot = Math::VInterpNormalRotationTo(Receptionist.HeadMesh.ForwardVector, DesiredLookDirection, DeltaTime, RotationSpeed);
			Receptionist.SyncedHeadLookDirection.SetValue(CappedTargetRot);
		}
		// Debug::DrawDebugLine(Receptionist.ActorLocation, Receptionist.InterestPoint.Location, ColorDebug::Ruby, 5.0, 0.0, true);
		// Debug::DrawDebugLine(Receptionist.InterestPoint.Location, Receptionist.InterestPoint.Location + Receptionist.InterestPoint.Rotation.ForwardVector * 100.0, ColorDebug::Cyan, 5.0, 0.0, true);
	}

};