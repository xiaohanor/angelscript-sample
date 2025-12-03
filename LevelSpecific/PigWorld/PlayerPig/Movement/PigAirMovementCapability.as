class UPigAirMovementCapability : UHazePlayerCapability
{
	default DebugCategory = PigTags::Pig;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default TickGroup = EHazeTickGroup::LastMovement;

	UPlayerPigComponent PigComponent;
	UPlayerMovementComponent MovementComponent;
	UPlayerAirMotionComponent AirMotionComponent;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// If we find a follow velocity component on the object we just left
		if (MovementComponent.PreviousGroundContact.IsValidBlockingHit())
		{
			UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MovementComponent.GetPreviousGroundContact().Actor.GetComponent(UPlayerInheritVelocityComponent));
			if(VelocityComp != nullptr)
			{
				FVector HorizontalVelocity = MovementComponent.GetHorizontalVelocity();
				FVector VerticalVelocity = MovementComponent.GetVerticalVelocity();

				VelocityComp.AddFollowAdjustedVelocity(MovementComponent, HorizontalVelocity, VerticalVelocity);
				Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				MoveData.AddHorizontalVelocity(AirControlVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();
				MoveData.AddPendingImpulses();

				const float CurrentFallingSpeed = Math::Max((-MovementComponent.WorldUp).DotProduct(MovementComponent.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComponent.Settings.MaximumTurnRateFallingSpeed) / AirMotionComponent.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComponent.Settings.MaximumTurnRate, AirMotionComponent.Settings.MinimumTurnRate, RotationSpeedAlpha);
				MoveData.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size());

				MoveData.RequestFallingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}
		}

		MovementComponent.ApplyMove(MoveData);

		// Just request loco tag for now
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"AirMovement", this);
	}
}