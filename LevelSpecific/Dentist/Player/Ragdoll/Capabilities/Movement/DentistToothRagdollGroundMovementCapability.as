class UDentistToothRagdollGroundMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;

	UDentistToothRagdollComponent RagdollComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();

		RagdollComp = UDentistToothRagdollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
			
		if(!RagdollComp.ShouldDoRagdollMovement())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!RagdollComp.ShouldDoRagdollMovement())
			return true;

		if(MoveComp.IsInAir())
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			CalculateDeltaMove(DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
	}

	void CalculateDeltaMove(const float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector Delta = Velocity * DeltaTime;

		FVector VerticalVelocity = Velocity.ProjectOnTo(FVector::UpVector);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		const float SlopeAngleDeg = MoveComp.GroundContact.Normal.GetAngleDegreesTo(FVector::UpVector);
		const bool bIsOnSlope = SlopeAngleDeg > RagdollComp.Settings.MinSlopeAngle;
		const FVector SlopeDir = GetSlopeDirection();

		if(bIsOnSlope)
		{
			FVector HorizontalVelocityAlongSlope = HorizontalVelocity.ProjectOnToNormal(SlopeDir);
			FVector HorizontalVelocitySideSlope = HorizontalVelocity - HorizontalVelocityAlongSlope;
			const bool bIsMovingUpSlope = HorizontalVelocity.DotProduct(SlopeDir) < 0;

			if(bIsMovingUpSlope)
			{
				HorizontalVelocityAlongSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocityAlongSlope, 0, DeltaTime, RagdollComp.Settings.UpSlopeDeceleration, Delta);
				HorizontalVelocitySideSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocitySideSlope, 0, DeltaTime, RagdollComp.Settings.UpSlopeSideDeceleration, Delta);
			}
			else
			{
				HorizontalVelocityAlongSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocityAlongSlope, 0, DeltaTime, RagdollComp.Settings.DownSlopeDeceleration, Delta);
				HorizontalVelocitySideSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocitySideSlope, 0, DeltaTime, RagdollComp.Settings.DownSlopeSideDeceleration, Delta);
			}

			HorizontalVelocity = HorizontalVelocitySideSlope + HorizontalVelocityAlongSlope;
		}
		else
		{
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, 0, DeltaTime, RagdollComp.Settings.GroundDeceleration, Delta);
		}

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, HorizontalVelocity.GetClampedToMaxSize(RagdollComp.Settings.GroundMaxHorizontalSpeed), DeltaTime, RagdollComp.Settings.GroundMaxSpeedDeceleration, Delta);
		}

		// Gravity
		Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, FVector::DownVector * 2500, DeltaTime, Delta);

		Velocity = HorizontalVelocity + VerticalVelocity;

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > RagdollComp.Settings.GroundMaxHorizontalSpeed;
	}

	FVector GetSlopeDirection() const
	{
		const FVector SlopePlane = MoveComp.GroundContact.ImpactNormal;

		// First project on to global up, then the slope plane.
		// This should give a vector pointing down the slope
		FVector SlopeDir = SlopePlane.ProjectOnTo(FVector::UpVector).GetSafeNormal();
		SlopeDir = SlopeDir.VectorPlaneProject(SlopePlane).GetSafeNormal();

		return -SlopeDir;
	}
};