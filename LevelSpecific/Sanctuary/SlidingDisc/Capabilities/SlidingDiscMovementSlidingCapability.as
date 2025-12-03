class USlidingDiscMovementSlidingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default CapabilityTags.Add(SlidingDiscTags::SlidingDiscMovement);
	default TickGroupOrder = 90;

	UHazeMovementComponent MovementComponent;
	UFloatingMovementData Movement;
	ASlidingDisc SlidingDisc;

	FRotator OGDiscRot;
	bool bActivatedOnce = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupMovementData(UFloatingMovementData);
		SlidingDisc = Cast<ASlidingDisc>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SlidingDisc.bIsSliding)
			return false;

		if (SlidingDisc.bDisintegrated)
			return false;

		if(MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SlidingDisc.bIsSliding)
			return true;

		if (SlidingDisc.bDisintegrated)
			return true;

		if(MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!bActivatedOnce)
		{
			bActivatedOnce = true;
			OGDiscRot = SlidingDisc.ActorRotation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if (SlidingDisc.IgnoreCollisionBoat != nullptr)
					Movement.IgnoreActorForThisFrame(SlidingDisc.IgnoreCollisionBoat);

				if (SlidingDiscDevToggles::DisableDiscMovement.IsEnabled())
					Movement.AddDelta(FVector());
				else
				{
					Movement.AddOwnerVelocity();
					FVector TurnForce = FVector::ZeroVector;
					if (MovementComponent.HasGroundContact())
						TurnForce = MovementComponent.WorldUp.CrossProduct(MovementComponent.Velocity.GetSafeNormal()).GetSafeNormal() * MovementComponent.Velocity.Size() * 0.5 * SlidingDisc.Lean;
					else
						Movement.SetRotation(OGDiscRot);
					FVector Acceleration = SlidingDisc.SlidingGravity * MovementComponent.GravityMultiplier + TurnForce - MovementComponent.Velocity * SlidingDisc.SlidingDrag + SlidingDisc.BoostForce;
					Movement.AddAcceleration(Acceleration);
					
					if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
					{
						Debug::DrawDebugCoordinateSystem(Game::Mio.ActorLocation, SlidingDisc.ActorRotation, 500.0, 10.0, 0.0, true);
					}
#if EDITOR
					TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Acceleration", Acceleration.Size());
					TEMPORAL_LOG(SlidingDisc).Arrow("Turn Force", Owner.ActorLocation, Owner.ActorLocation + Acceleration, 3.0, 20.0, ColorDebug::Magenta);
#endif
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			MovementComponent.ApplyMove(Movement);

			if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			{
				PrintToScreen("Speed: " + MovementComponent.Velocity.Size(), 0.0, FLinearColor::Green);
			}
#if EDITOR
			TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Speed", MovementComponent.Velocity.Size());
			DevPrintString("Velocity", "" + MovementComponent.Velocity.Size(), 0.0);
#endif
		}
	}
}

