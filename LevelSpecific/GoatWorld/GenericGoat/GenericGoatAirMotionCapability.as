
class UGenericGoatAirMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 160;

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerLandingComponent LandingComp;
	USteppingMovementData Movement;
	bool bUseGroundedTraceDistance = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);

		// If we find a follow velocity component on the object we just left
		if (MoveComp.PreviousGroundContact.IsValidBlockingHit())
		{
			UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GetPreviousGroundContact().Actor.GetComponent(UPlayerInheritVelocityComponent));
			if(VelocityComp != nullptr)
			{
				FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
				FVector VerticalVelocity = MoveComp.GetVerticalVelocity();

				VelocityComp.AddFollowAdjustedVelocity(MoveComp, HorizontalVelocity, VerticalVelocity);
				Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		bUseGroundedTraceDistance = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);

				// Debug::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation + (MoveComp.MovementInput.GetSafeNormal() * 125.0), LineColor = FLinearColor::Green);
				// Debug::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation + (MoveComp.HorizontalVelocity.GetSafeNormal() * 125.0), LineColor = FLinearColor::Red);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				/*
					Calculate how fast the player should rotate when falling at fast speeds
				*/
				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// If this is the reset frame, we use a bigger stepdown
			// to find out if we are grounded or not
			if(!MoveComp.bHasPerformedAnyMovementSinceReset || bUseGroundedTraceDistance)
			{
				Movement.ForceGroundedStepDownSize();
			}

			// We need to request grounded if this capability finds
			// the ground, else we will get a small step animation
			// in the beginning after a reset
			if(MoveComp.IsOnAnyGround())
			{
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
				bUseGroundedTraceDistance = true;
			}
			else
			{
				Movement.RequestFallingForThisFrame();
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
			}
		}
	}
}