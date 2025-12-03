class UCarChaseTetherMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(n"PlayerToCarTether");
	default CapabilityTags.Add(n"PlayerToCarTetherMovement");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 38;
	default TickGroupSubPlacement = 24;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 18, 21);

	UPlayerMovementComponent MoveComp;
	UCarChaseTetherPlayerComponent TetherComp;
	USweepingMovementData Movement;

	FRotator InitialAttachRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		TetherComp = UCarChaseTetherPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!TetherComp.HasActivatedTetherPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!TetherComp.HasActivatedTetherPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Set anim data

		// FVector FlatFacing = TetherComp.PlayerToTetherPoint.ConstrainToPlane(TetherComp.Data.ActiveTetherPoint.Owner.ActorForwardVector).GetSafeNormal();
		InitialAttachRotation = FRotator::MakeFromXZ(-TetherComp.Data.ActiveTetherPoint.Owner.ActorUpVector, TetherComp.Data.ActiveTetherPoint.Owner.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(TetherComp.Data.bTetherTaut)
			TetherComp.Data.AcceleratedTetherLength.AccelerateTo(TetherComp.Settings.TetherLength, 4.0, DeltaTime);

		FVector Velocity = MoveComp.Velocity;

		FVector PlayerToTetherPointDirection = TetherComp.PlayerToTetherPoint.GetSafeNormal();
		FVector BiTangent = MoveComp.WorldUp.CrossProduct(PlayerToTetherPointDirection);
		FVector SwingSlope = BiTangent.CrossProduct(PlayerToTetherPointDirection);

		if(MoveComp.MovementInput.IsNearlyZero() || IsActioning(ActionNames::Grapple))
		{
			//Player isnt giving / doesnt have input

			FVector Drag = Velocity * 0.6 * DeltaTime;
			Velocity -= Drag;

			//Set animation data
		}
		else
		{
			//Player is giving input

			//Drag
			FVector DragDirection = MoveComp.WorldUp.CrossProduct(MoveComp.MovementInput).GetSafeNormal();
			FVector HorizontalVelocity = DragDirection * Velocity.DotProduct(DragDirection);
			FVector OtherVelocity = Velocity - HorizontalVelocity;

			HorizontalVelocity -= HorizontalVelocity * 1.2 * DeltaTime;
			OtherVelocity -= OtherVelocity * 0.5 * DeltaTime;
			Velocity = HorizontalVelocity + OtherVelocity;

			//Quick fix for input conversion
			FVector2D InputRaw = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			FVector MoveInput = TetherComp.Data.ActiveTetherPoint.Owner.ActorRightVector * InputRaw.X;
			MoveInput += TetherComp.Data.ActiveTetherPoint.Owner.ActorUpVector * InputRaw.Y;

			const float InputSpeed = 5000.0;
			const float RopeLength = 600.0;
			float VelocityStrength = InputSpeed * (TetherComp.Data.TetherLength / RopeLength);

			Velocity += MoveInput * VelocityStrength * DeltaTime;

			//Set anim data
			FVector PushDirection = Player.ActorRotation.UnrotateVector(MoveInput);
		}

		FVector GravityVelocity;
		if(MoveComp.WorldUp.DotProduct(Velocity) > 0.0 && !TetherComp.Data.bTetherTaut)
			GravityVelocity = -MoveComp.WorldUp * TetherComp.Settings.GravityAcceleration;
		else
		{
			float GravityScale = Math::Pow(SwingSlope.Size(), 0.75);
			GravityVelocity = SwingSlope.GetSafeNormal() * GravityScale * TetherComp.Settings.GravityAcceleration;
		}

		Velocity += GravityVelocity * DeltaTime;

		FVector DeltaMove = Velocity * DeltaTime;
		TetherComp.ConstrainVelocityToTetherPoint(Velocity, DeltaMove);

		Movement.SetRotation(InitialAttachRotation);
		Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
		Movement.AddPendingImpulses();

		//Rotate towards input
		// if(ActiveDuration <= 0.3)
			//Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, InitialAttachRotation, DeltaTime, 8.0));
		// else if(!MoveComp.MovementInput.IsNearlyZero())
		// {
		// 	FVector FacingInput = MoveComp.MovementInput;
		// 	FRotator CameraRotation = Player.ControlRotation;
		// 	CameraRotation.Pitch = 0.0;

		// 	float Dot = FacingInput.DotProduct(CameraRotation.ForwardVector);
		// 	if(Dot < 0.0)
		// 		FacingInput -= CameraRotation.ForwardVector * Dot * 2.0;

		// 	FRotator TargetRotation = FRotator::MakeFromXZ(FacingInput.GetSafeNormal(), MoveComp.WorldUp);
		// 	Movement.SetRotation(Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 60.0 * FacingInput.Size()));
		// }

		MoveComp.ApplyMove(Movement);
		// MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"CarChaseTether");
	}
}