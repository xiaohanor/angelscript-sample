class UPigSiloJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigSiloComponent PigSiloComponent;
	UPlayerAirMotionComponent AirMotionComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UPigSiloMovementSettings MovementSettings;

	FSplinePosition SplinePosition;

	const float JumpDuration = 0.7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		AirMotionComponent = UPlayerAirMotionComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();
		MovementSettings = UPigSiloMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PigSiloComponent.IsSiloMovementActive())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasUpwardsImpulse())
			return false;

		if (!PigSiloComponent.IsSiloMovementActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (MovementComponent.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PigSiloComponent.bJumping = true;

		float DistanceAlongSpline = PigSiloComponent.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		SplinePosition = FSplinePosition(PigSiloComponent.CurrentSpline, DistanceAlongSpline, true);

		// Add impulse and set velocity
		FVector HorizontalVelocity = Player.ActorForwardVector * MovementSettings.CurrentMoveSpeed;
		HorizontalVelocity = MovementComponent.HorizontalVelocity;
		FVector VerticalVelocity = MovementComponent.WorldUp * UPigMovementSettings::GetSettings(Player).JumpImpulse;
		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(PigTags::SpecialAbility, this);

		Player.PlayForceFeedback(PigSiloComponent.JumpFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PigSiloComponent.bJumping = false;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(PigTags::SpecialAbility, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				// MoveData.AddHorizontalVelocity(AirControlVelocity);

				// MoveData.AddOwnerVerticalVelocity();
				// MoveData.AddGravityAcceleration();

				// MoveData.InterpRotationToTargetFacingRotation(UPlayerJumpSettings::GetSettings(Player).FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size());

				// FVector HorizontalVelocity = MovementComponent.Velocity.ConstrainToPlane(Player.MovementWorldUp);
				// HorizontalVelocity = MovementComponent.Velocity.ConstrainToDirection(SplinePosition.GetWorldForwardVector());

				// Update movement on spline
				FVector HorizontalVelocity = SplinePosition.GetWorldForwardVector() * MovementSettings.CurrentMoveSpeed;
				float SplineMoveDelta = HorizontalVelocity.Size() * DeltaTime;
				SplinePosition.Move(SplineMoveDelta);
				PigSiloComponent.CurrentSpline = SplinePosition.CurrentSpline;

				// Move
				FVector TargetSplineLocation = SplinePosition.GetWorldLocation() + SplinePosition.GetWorldRightVector() * PigSiloComponent.SiloPlatform.GetHorizontalOffsetForPlayer(Player);
				FVector HorizontalMoveDelta = (TargetSplineLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);
				MoveData.AddDelta(HorizontalMoveDelta);

				// MoveData.AddVelocity(HorizontalMoveDelta);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				MoveData.RequestFallingForThisFrame();

				MoveData.SetRotation(SplinePosition.WorldForwardVector.Rotation());
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(GetLocomotionTag(), this);
	}

	FName GetLocomotionTag() const
	{
		if (ActiveDuration < JumpDuration)
			return n"Jump";

		return n"AirMovement";
	}
}