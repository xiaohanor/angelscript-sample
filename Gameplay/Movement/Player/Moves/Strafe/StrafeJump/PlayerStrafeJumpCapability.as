
class UPlayerStrafeJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Strafe);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 39;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerStrafeJumpComponent StrafeJumpComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerAirMotionComponent AirMotionComp;

	float HorizontalMoveSpeed;
	float HorizontalVelocityInterpSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		StrafeJumpComp = UPlayerStrafeJumpComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (!StrafeComp.IsStrafeEnabled())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if(MoveComp.HasImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!StrafeComp.IsStrafeEnabled())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if(MoveComp.HasImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		Player.BlockCapabilities(BlockedWhileIn::Strafe, this);

		// Add jump impulse
		FVector VerticalVelocity = MoveComp.WorldUp * StrafeJumpComp.Settings.Impulse;
		Player.SetActorVerticalVelocity(VerticalVelocity);
		HorizontalMoveSpeed = MoveComp.HorizontalVelocity.Size() + 100.0;
		HorizontalVelocityInterpSpeed = HorizontalMoveSpeed * 3.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);
		Player.UnblockCapabilities(BlockedWhileIn::Strafe, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator TargetFacingRotation = StrafeComp.GetDefaultFacingRotation(Player);
		Player.SetMovementFacingDirection(TargetFacingRotation);

		if(MoveComp.PrepareMove(Movement))
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

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"StrafeJump");
		}
	}
}