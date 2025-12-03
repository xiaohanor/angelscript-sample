
class UGenericGoatStrafeAirMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Strafe);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 130;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerStrafeAirComponent StrafeAirComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerAirMotionComponent AirMotionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		StrafeAirComp = UPlayerStrafeAirComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!StrafeComp.IsStrafeEnabled())
			return false;

		if (MoveComp.IsInAir())
			return true;
		
		// We have an impulse that will push us of the ground.
		if(MoveComp.HasUpwardsImpulse(1.0))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!StrafeComp.IsStrafeEnabled())
			return true;

		if (MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		Player.BlockCapabilities(BlockedWhileIn::Strafe, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		Player.UnblockCapabilities(BlockedWhileIn::Strafe, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator TargetFacingRotation = StrafeComp.GetDefaultFacingRotation(Player);
		Player.SetMovementFacingDirection(TargetFacingRotation);

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				StrafeComp.AnimData.bHasInput = !MoveComp.MovementInput.IsNearlyZero();

				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
					AirMovementSpeedMultiplier = StrafeComp.Settings.StrafeMoveScale,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);
				
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				FVector RelativeVelocity = Owner.ActorTransform.InverseTransformVectorNoScale(MoveComp.HorizontalVelocity);
				StrafeComp.AnimData.BlendSpaceVector = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);

				TargetFacingRotation.Pitch = 0.0;
				FRotator NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetFacingRotation, DeltaTime, StrafeComp.Settings.FacingDirectionInterpSpeed);
				Movement.SetRotation(NewRotation);	
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"StrafeAir");
		}
	}

}