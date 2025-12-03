class UDentistToothRagdollAirMovementCapability : UHazePlayerCapability
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

		if(MoveComp.IsOnWalkableGround())
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

		if(MoveComp.IsOnWalkableGround())
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
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
	}

	void CalculateDeltaMove(const float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector Delta = Velocity * DeltaTime;
		FVector MovementInput = MoveComp.MovementInput;

		FVector VerticalVelocity = Velocity.ProjectOnTo(FVector::UpVector);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		if(RagdollComp.bAllowAirMovement.Get())
		{
			// Input
			const bool bIsInputting = !MovementInput.IsNearlyZero();

			if(bIsInputting)
			{
				const bool bIsAccelerating = HorizontalVelocity.DotProduct(MovementInput) > 0;
				const bool bIsRebound = !bIsAccelerating;

				float Multiplier = 1;
				if(bIsRebound)
					Multiplier *= Math::Lerp(1, RagdollComp.Settings.AirReboundMultiplier, MovementInput.DotProduct(HorizontalVelocity.GetSafeNormal()));

				if(!IsOverHorizontalMaxSpeed(HorizontalVelocity) || !bIsAccelerating)
				{
					// If we are below max speed, or decelerating, apply movement input
					FVector Acceleration = MovementInput * RagdollComp.Settings.AirAcceleration * Multiplier;
					Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, Acceleration, DeltaTime, Delta);
				}
			}
		}

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, HorizontalVelocity.GetClampedToMaxSize(RagdollComp.Settings.AirMaxHorizontalSpeed), DeltaTime, RagdollComp.Settings.AirMaxSpeedDeceleration, Delta);
		}

		if(MoveComp.HasUnstableGroundContactEdge())
		{
			FVector DeltaToEdge = MoveComp.GroundContact.ImpactPoint - Player.ActorLocation;
			float DistanceToEdge = DeltaToEdge.DotProduct(-MoveComp.GroundContactEdge.EdgeNormal);
			float DistanceToEdgeAlpha = Math::Saturate(DistanceToEdge / Player.CapsuleComponent.CapsuleRadius);

			// If we are more than halfway off the edge, start pushing us off. This threshold allows the player some form of control when almost on an edge.
			if(DistanceToEdgeAlpha > 0.5)
			{
				// Block ground tracing to prevent landing on the edge
				MoveData.BlockGroundTracingForThisFrame();

				// If we are trying to move in towards the edge, negate that velocity so that we can only move along (or off) the edge
				if(Velocity.DotProduct(MoveComp.GroundContactEdge.EdgeNormal) < 0)
				{
					FVector VelocityAlongNormal = Velocity.ProjectOnToNormal(MoveComp.GroundContactEdge.EdgeNormal);
					Velocity -= VelocityAlongNormal;
				}

				// Add a push off force proportional to how much we are intersecting with the edge
				DistanceToEdgeAlpha = Math::NormalizeToRange(DistanceToEdgeAlpha, 0.5, 1);
				DistanceToEdgeAlpha = Math::SmoothStep(0, 1, DistanceToEdgeAlpha);
				Velocity += (MoveComp.GroundContactEdge.EdgeNormal * DistanceToEdgeAlpha * RagdollComp.Settings.PushOffEdgeForce) + FVector::UpVector;
			}
		}

		// Gravity
		Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, FVector::DownVector * 2500, DeltaTime, Delta);

		// Limit falling speed
		if(VerticalVelocity.Z < -Math::Abs(RagdollComp.Settings.AirMaxFallSpeed))
		{
			VerticalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(VerticalVelocity, VerticalVelocity.GetClampedToMaxSize(Math::Abs(RagdollComp.Settings.AirMaxFallSpeed)), DeltaTime, RagdollComp.Settings.AirMaxFallDeceleration, Delta);
		}

		Velocity = HorizontalVelocity + VerticalVelocity;

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	}

	private bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > RagdollComp.Settings.AirMaxHorizontalSpeed;
	}
};