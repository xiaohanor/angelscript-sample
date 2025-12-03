class UMoonMarketPlayerBalloonSwingJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingJump);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 38;
	default TickGroupSubPlacement = 20;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 18, 20);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;	
	UPlayerSwingComponent SwingComp;
	USweepingMovementData Movement;
	UPlayerAirMotionComponent AirMotionComp;
	UMoonMarketHoldBalloonComp HoldBalloonComp;

	FVector InitialJumpVelocity;
	float InitialHorizontalJumpSpeed = 0.0;
	FVector JumpDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		HoldBalloonComp = UMoonMarketHoldBalloonComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HoldBalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return false;
		
		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwingComp.HasActivateSwingPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialJumpVelocity = GetJumpVelocity();
		Player.SetActorVelocity(InitialJumpVelocity);

		JumpDirection = InitialJumpVelocity.ConstrainToPlane(MoveComp.WorldUp);
		InitialHorizontalJumpSpeed = JumpDirection.Size();
		JumpDirection.Normalize();

		FVector RelativeJumpDirection = Player.ActorRotation.UnrotateVector(JumpDirection);
		SwingComp.AnimData.State = EPlayerSwingState::Jump;	
		SwingComp.AnimData.JumpDirection = FVector2D(RelativeJumpDirection.Y, RelativeJumpDirection.X);
		SwingComp.StopSwinging();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;
		
		FRotator StartRotation = Owner.ActorRotation;
		if (HasControl())
		{
			const float InputScale = Math::Clamp((ActiveDuration - 0.0) / 1.0, SMALL_NUMBER, 0.4);
			FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();		
			HorizontalVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
				MoveComp.MovementInput,
				HorizontalVelocity,
				DeltaTime,
			);
			Movement.AddVelocity(HorizontalVelocity);

			FVector GravityAcceleration = -MoveComp.WorldUp * (2200.0 * MoveComp.GravityMultiplier) * DeltaTime;
			Movement.AddVelocity(GravityAcceleration);
			Movement.AddOwnerVerticalVelocity();

			FRotator TargetRotation = FRotator::MakeFromXZ(HorizontalVelocity.GetSafeNormal(), MoveComp.WorldUp);
			Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 360.0));
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		FName AnimTag = ActiveDuration > 0.0 ? n"AirMovement" : n"SwingAir";
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);

		SwingComp.AnimData.bJumpRotatingRight = (StartRotation.Yaw - Owner.ActorRotation.Yaw) < 0.0;
	}

	FVector GetJumpVelocity() const
	{
		const FVector DirToSwingPoint = SwingComp.PlayerToSwingPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		FVector Velocity = MoveComp.Velocity;

		FVector VerticalVelocity = Velocity.ConstrainToDirection(MoveComp.WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		/*
			If you jump off when you start swinging towards the swing point again
			Flip velocity to protect against jumping backwards
		*/
		const float SpeedToSwingPoint = HorizontalVelocity.DotProduct(DirToSwingPoint);
		const bool bSwingingWideEnough = SwingComp.SwingAngle > 30.0;
		const bool bSwingingBackwardsSlowEnough = SpeedToSwingPoint >= 0.0 && SpeedToSwingPoint <= 300.0;

		if (bSwingingWideEnough && bSwingingBackwardsSlowEnough)
		{
			float ReflectionAmount = HorizontalVelocity.DotProduct(DirToSwingPoint);
			HorizontalVelocity -= DirToSwingPoint * ReflectionAmount * 2.0;

			if (VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0.0)
				VerticalVelocity = -VerticalVelocity;
		}

		VerticalVelocity += MoveComp.WorldUp * 500.0;
		VerticalVelocity = VerticalVelocity.GetClampedToSize(0.0, 1250.0);
		HorizontalVelocity = HorizontalVelocity.GetClampedToSize(900.0, 1200.0);


		// if (!MoveComp.MovementInput.IsNearlyZero())
		// {
		// 	const float ClampRange = 50.0;

		// 	FVector FlattenedVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		// 	float InputAngularDifference = FlattenedVelocity.AngularDistance(MoveComp.MovementInput) * RAD_TO_DEG;
		// 	InputAngularDifference = Math::Min(InputAngularDifference, ClampRange);
			

		// 	Velocity = FQuat(MoveComp.WorldUp, InputAngularDifference * DEG_TO_RAD) * Velocity;

		// 	PrintToScreenScaled("InputAngularDifference: " + InputAngularDifference);
		// }
			
		//LaunchDirection.RotateVectorTowardsAroundAxis()

		return VerticalVelocity + HorizontalVelocity;
	}
}