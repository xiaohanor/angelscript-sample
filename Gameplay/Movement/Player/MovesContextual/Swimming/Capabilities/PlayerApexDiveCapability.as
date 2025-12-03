class UPlayerApexDiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);
	default CapabilityTags.Add(PlayerMovementTags::ApexDive);
	default CapabilityTags.Add(PlayerMovementTags::LandingApexDive);

	default CapabilityTags.Add(BlockedWhileIn::ShapeShiftForm);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Skydive);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 155;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 30);

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerSwimmingComponent SwimComp;
	UPlayerAirMotionComponent AirMotionComp;

	const float BackwardsBrakeAngle = 45;
	const float MINIMUM_DIVE_VERTICAL = 200;
	FVector ImpactLocation;

	//[AL] Might want to make a "Dive transition to underwater" capability where we remove control briefly while we bend the velocity to a world up constrained plane alignment
	//OR it might be enough to just do what we are currently doing, blocking surface for a minor duration

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		SwimComp = UPlayerSwimmingComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!AirMotionComp.AirMotionData.bDiveDetected)
			return false;

		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) >= -500)
			return false;

		if (!VerifyImpactDistance())
			return false;

		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::ApexDive, this);
		ImpactLocation = AirMotionComp.AirMotionData.CurrentPredictedDiveHit.ImpactPoint;
		AirMotionComp.AirMotionData.ResetData();

		FSwimmingEffectEventData Data;
		UPlayerSwimmingEffectHandler::Trigger_ApexDive_Detected(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::ApexDive, this);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = ImpactLocation;
		ImpactLocation = FVector::ZeroVector;
		UPlayerSwimmingEffectHandler::Trigger_Surface_ApexDive_Impacted(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector AirControlVelocity;

				if (MoveComp.MovementInput.GetAngleDegreesTo((MoveComp.HorizontalVelocity.Size() > KINDA_SMALL_NUMBER) ? MoveComp.HorizontalVelocity.GetSafeNormal() : Player.ActorForwardVector) >= 145)
				{
					//if we are inputting heavily backwards then just slow us down horizontally and hold our rotation
					AirControlVelocity = Math::VInterpTo(MoveComp.HorizontalVelocity, FVector::ZeroVector, DeltaTime, 1);
				}
				else
				{
					AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
						MoveComp.MovementInput,
						MoveComp.HorizontalVelocity,
						DeltaTime,
						0.5,
					);

					Movement.InterpRotationToTargetFacingRotation(AirMotionComp.Settings.ApexDiveTurnRate * MoveComp.MovementInput.Size());
				}

				Movement.AddHorizontalVelocity(AirControlVelocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"ApexDive");
		}
	}

	//Check if we are to close to the surface to initiate a dive
	bool VerifyImpactDistance() const
	{
		FVector PlayerToSurfaceDelta = AirMotionComp.AirMotionData.CurrentPredictedDiveHit.ImpactPoint - Player.ActorLocation;
		float PlayerToSurfaceVerticalDelta = PlayerToSurfaceDelta.DotProduct(-MoveComp.WorldUp);

		if(PlayerToSurfaceVerticalDelta < MINIMUM_DIVE_VERTICAL)
			return false;

		return true;
	}
};