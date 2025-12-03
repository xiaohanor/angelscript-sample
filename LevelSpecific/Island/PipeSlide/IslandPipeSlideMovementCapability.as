class UIslandPipeSlideMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UIslandPipeSlideComponent PipeSlideComponent;
	UIslandPipeSlideComposableSettings Settings;
	AHazePlayerCharacter Player;

	float ForwardMoveSpeed = 0;
	float LeftRigthMoveSpeed = 0;

	FVector TestVector = FVector::UpVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PipeSlideComponent = UIslandPipeSlideComponent::Get(Player);
		Settings = UIslandPipeSlideComposableSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PipeSlideComponent.bIsPipeSliding)
			return false;

		if(PipeSlideComponent.ActiveSpline == nullptr)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PipeSlideComponent.bIsPipeSliding)
			return true;

		if(PipeSlideComponent.ActiveSpline == nullptr)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 70, this);

		FSplinePosition SplinePos = PipeSlideComponent.ActiveSpline.GetClosestSplinePositionToWorldLocation(Player.GetActorLocation());
		ForwardMoveSpeed = Player.GetActorHorizontalVelocity().DotProduct(Player.MovementWorldUp.VectorPlaneProject(SplinePos.WorldForwardVector).GetSafeNormal());
		ForwardMoveSpeed = Math::Max(ForwardMoveSpeed, Settings.MoveInputSpeed.Min);
		LeftRigthMoveSpeed = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearGravityDirectionOverride(this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.MeshOffsetComponent.SetRelativeRotation(FRotator::ZeroRotator);
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FSplinePosition SplinePos = PipeSlideComponent.ActiveSpline.GetClosestSplinePositionToWorldLocation(Player.GetActorLocation());
		FVector WorldUp = Player.GetMovementWorldUp();

		// Override the world up
		if(MoveComp.IsOnAnyGround())
		{
			FVector ForwardSplineDir = SplinePos.WorldForwardVector.VectorPlaneProject(Player.MovementWorldUp).GetSafeNormal();
			WorldUp = (SplinePos.WorldLocation - Player.GetActorLocation());
			WorldUp = WorldUp.VectorPlaneProject(ForwardSplineDir).GetSafeNormal();
			WorldUp = Math::VInterpTo(Player.MovementWorldUp, WorldUp, DeltaTime, 10.0).GetSafeNormal();
			Player.OverrideGravityDirection(-WorldUp, this);
		}

		// Gravitate away from the spline
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				const FVector ForwardSplineDir = WorldUp.VectorPlaneProject(SplinePos.WorldForwardVector).GetSafeNormal();
				const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				// Update the forward speed
				{
					const float TargetMoveSpeed = Math::Lerp(Settings.MoveInputSpeed.Min, Settings.MoveInputSpeed.Max, (RawStick.X + 1.0) * 0.5);
					if(TargetMoveSpeed > ForwardMoveSpeed)
					{
						ForwardMoveSpeed = Math::FInterpTo(ForwardMoveSpeed, TargetMoveSpeed, DeltaTime, Settings.MoveSpeedAcceleration);
					}
					else if(TargetMoveSpeed < ForwardMoveSpeed)
					{
						ForwardMoveSpeed = Math::FInterpTo(ForwardMoveSpeed, TargetMoveSpeed, DeltaTime, Settings.MoveSpeedDeceleration);
					}
					ForwardMoveSpeed *= MoveComp.MovementSpeedMultiplier;
					Movement.AddHorizontalVelocity(SplinePos.WorldForwardVector * ForwardMoveSpeed);
				}

				// Update left right speed
				{
					float LeftRightInputAlpha = RawStick.Y;	
					float UpsideDownMoveSpeedMultiplier = FVector::UpVector.DotProductNormalized(WorldUp);
					FVector LeftRightSplineDir = FQuat::MakeFromXZ(ForwardSplineDir, WorldUp).RightVector;

					LeftRigthMoveSpeed = Math::FInterpTo(LeftRigthMoveSpeed, ForwardMoveSpeed * Settings.LeftRightMoveSpeedMultiplier * UpsideDownMoveSpeedMultiplier * LeftRightInputAlpha, DeltaTime, Settings.MoveSpeedAcceleration);
					LeftRigthMoveSpeed *= MoveComp.MovementSpeedMultiplier;
					Movement.AddHorizontalVelocity(LeftRightSplineDir * LeftRigthMoveSpeed);
				}	

				// Move back to origo
				{
					float DirBack = -Player.ActorRightVector.DotProduct(FVector::UpVector);
					float LeftRightInputAlpha = Math::Lerp(DirBack, 0.0, Math::Pow(Math::Abs(RawStick.Y), 2.0));	
					float UpsideDownMoveSpeedMultiplier = FVector::UpVector.DotProductNormalized(WorldUp);
					FVector LeftRightSplineDir = FQuat::MakeFromXZ(ForwardSplineDir, WorldUp).RightVector;

					LeftRigthMoveSpeed = Math::FInterpTo(LeftRigthMoveSpeed, ForwardMoveSpeed * Settings.LeftRightMoveSpeedMultiplier * UpsideDownMoveSpeedMultiplier * LeftRightInputAlpha, DeltaTime, Settings.MoveSpeedAcceleration);
					LeftRigthMoveSpeed *= MoveComp.MovementSpeedMultiplier;
					Movement.AddHorizontalVelocity(LeftRightSplineDir * LeftRigthMoveSpeed);
				}

				// Jump
				{
					if(WasActionStarted(ActionNames::MovementJump) && Settings.JumpImpulse > KINDA_SMALL_NUMBER)
					{
						Movement.AddVerticalVelocity(WorldUp * Settings.JumpImpulse);
					}
				}

				Movement.SetRotation(SplinePos.WorldForwardVector.ToOrientationQuat());
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}

			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();			
			}

			Player.MeshOffsetComponent.SetWorldRotation(FQuat::MakeFromXZ(SplinePos.WorldForwardVector, WorldUp));
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"PipeSlide");	

			// End of spline
			SplinePos = PipeSlideComponent.ActiveSpline.GetClosestSplinePositionToWorldLocation(Player.GetActorLocation());
			if(!SplinePos.Move(1))
			{
				StopIslandPipeSlide(Player);
			}
		}
	}
};