class USkylineInnerReceptionistMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	ASkylineInnerReceptionistBot Receptionist;
	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (Receptionist.HitOrDead())
					Movement.AddDelta(FVector());
				else
					UpdateAliveMove(DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	private void UpdateAliveMove(float DeltaTime)
	{
		FVector TowardsInterestPoint = Receptionist.InterestPoint.Location - Receptionist.ActorLocation;
		TowardsInterestPoint.Z = 0.0;
		float DistanceToInterest = TowardsInterestPoint.Size();
		TowardsInterestPoint = TowardsInterestPoint.GetSafeNormal();

		FVector TargetRot = TowardsInterestPoint;
		bool bIsCorrectlyAligned = Receptionist.State == ESkylineInnerReceptionistBotState::Annoyed || Math::DotToDegrees(Receptionist.ActorForwardVector.DotProduct(TowardsInterestPoint)) < 1.0;
		bool bHasArrived = DistanceToInterest < Receptionist.StopInFrontOfInterestDistance;
		if (!bHasArrived && !bIsCorrectlyAligned)
			TargetRot = TowardsInterestPoint;
		else if (bHasArrived)
			TargetRot = Receptionist.InterestPoint.Rotation.ForwardVector;
		
		if (bIsCorrectlyAligned && !bHasArrived)
			AccSpeed.AccelerateTo(100.0, 1.0, DeltaTime);
		else
			AccSpeed.AccelerateTo(0.0, 0.1, DeltaTime);

		FVector DeltaMove = TowardsInterestPoint * AccSpeed.Value * DeltaTime;
		if (!GetImpact().bBlockingHit)
		{
			if (DeltaMove.Size() > KINDA_SMALL_NUMBER)
				Movement.AddDelta(DeltaMove);
			else
				Movement.AddDelta(FVector());
		}
		
		float RotationSpeed = Receptionist.State == ESkylineInnerReceptionistBotState::Annoyed ? 90.0 : 30.0 ;
		Movement.SetRotation(FRotator::MakeFromXZ(Math::VInterpNormalRotationTo(Receptionist.ActorForwardVector, TargetRot, DeltaTime, RotationSpeed), FVector::UpVector));
	}

	FHitResult GetImpact()
	{
		FHitResult HitResult;

		if (MoveComp.HasGroundContact())
			HitResult = MoveComp.GroundContact.ConvertToHitResult();

		if (MoveComp.HasWallContact())
			HitResult = MoveComp.WallContact.ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			HitResult = MoveComp.CeilingContact.ConvertToHitResult();

		return HitResult;
	}
};