
class UBattlefieldHoverboardSwingMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingMovement);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 38;
	default TickGroupSubPlacement = 23;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 18, 20);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	USweepingMovementData Movement;
	
	UBattlefieldHoverboardSwingComponent SwingComp;
	UPlayerTargetablesComponent TargetablesComp;

	FRotator InitialAttachRotation;

	UBattlefieldHoverboardSwingSettings SwingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwingComp = UBattlefieldHoverboardSwingComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);

		SwingSettings = UBattlefieldHoverboardSwingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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

		if (!SwingComp.HasActivateSwingPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.AnimData.State = EPlayerSwingState::Swing;

		FVector FlatFacing = SwingComp.PlayerToSwingPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		InitialAttachRotation = FRotator::MakeFromXZ(FlatFacing, MoveComp.WorldUp);

		Player.PlayForceFeedback(SwingComp.Settings.AttachSwingRumble, false, false, this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverboardComp.AccRotation.SnapTo(Player.ActorRotation);

		Player.PlayForceFeedback(SwingComp.Settings.DetachSwingRumble, false, false, this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;
		
		if (SwingComp.Data.bTetherTaut)
			SwingComp.Data.AcceleratedTetherLength.AccelerateTo(SwingComp.Settings.TetherLength, 5.0, DeltaTime);

		if (HasControl())
		{
			FVector MovementInput = Player.ActorRotation.RotateVector(MoveComp.MovementInput);
			FVector WorldMovementInput = HoverboardComp.GetMovementInputWorldSpace();

			HoverboardComp.AddWantedRotation(SwingSettings.WantedRotationSpeed, WorldMovementInput, DeltaTime);
			HoverboardComp.SetCameraWantedRotationToWantedRotation();

			FVector Velocity = MoveComp.Velocity;

			FVector PlayerToSwingPointDirection = SwingComp.PlayerToSwingPoint.GetSafeNormal();
			FVector BiTangent = MoveComp.WorldUp.CrossProduct(PlayerToSwingPointDirection);
			FVector SwingSlope = BiTangent.CrossProduct(PlayerToSwingPointDirection);				

			if(MovementInput.IsNearlyZero())
			{
				Velocity += Velocity.GetSafeNormal() * 2000.0 * DeltaTime; //adding some extra velocity based on current velocity otherwise swing feels super slow
				Velocity *= Math::Pow(SwingComp.Settings.DragCoefficient, DeltaTime);
				SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
			}
			else
			{
				float VelocityStrength = SwingComp.Settings.InputSpeed * (SwingComp.Data.TetherLength / SwingComp.Settings.RopeLength);
				FVector NoForwardMovementInput = MovementInput.ConstrainToPlane(Player.ActorForwardVector);
				// Velocity += NoForwardMovementInput * VelocityStrength * DeltaTime;
				Velocity += (MovementInput / 6) * VelocityStrength * DeltaTime;
				Velocity *= Math::Pow(SwingComp.Settings.DragCoefficient, DeltaTime);
				FVector PushDirection = Player.ActorRotation.UnrotateVector(MovementInput);
				SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);
			}

			
			FVector GravityAcceleration;
			if (MoveComp.WorldUp.DotProduct(Velocity) > 0.0 && !SwingComp.Data.bTetherTaut)
			{
				GravityAcceleration = -MoveComp.WorldUp * MoveComp.GetGravityForce();
			}
			else
			{
				float GravityScale = Math::Pow(SwingSlope.Size(), 0.75);
				GravityAcceleration = SwingSlope.GetSafeNormal() * GravityScale * 3000.0;
			}

			// Gravity should be applied as an acceleration directly to DeltaMove so it's not framerate dependent
			FVector DeltaMove = Velocity * DeltaTime;
			DeltaMove += GravityAcceleration * (DeltaTime * DeltaTime * 0.5);
			Velocity += GravityAcceleration * DeltaTime;

			SwingComp.ConstrainVelocityToSwingPoint(Velocity, DeltaMove);

			Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
			Movement.AddPendingImpulses();


			// Rotate Towards Input
			// 		TODO: Accelerate when you have input, and decelerate when you dont.
			if (ActiveDuration <= 0.3)
			{
				Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, InitialAttachRotation, DeltaTime, 8.0));	
			}
			else if (!MovementInput.IsNearlyZero())
			{
				FVector FacingInput = MovementInput;
				FRotator CameraRotation = Player.ControlRotation;
				CameraRotation.Pitch = 0.0;

				float Dot = FacingInput.DotProduct(CameraRotation.ForwardVector);
				if (Dot < 0.0)
					FacingInput -= CameraRotation.ForwardVector * Dot * 2.0;

				FRotator TargetRotation = FRotator::MakeFromXZ(FacingInput.GetSafeNormal(), MoveComp.WorldUp);
				Movement.SetRotation(Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 60.0 * FacingInput.Size()));			

				// Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"LeftAttach"), Player.Mesh.GetSocketLocation(n"LeftAttach") + FacingInput * 150.0, FLinearColor::Red, 2.0);
			}

			// Debug Draw
			if (IsDebugActive())
			{
				SwingComp.DebugDrawVelocity(Velocity, MoveComp.WorldUp * 10.0);
				SwingComp.DebugDrawGravity(GravityAcceleration, -MoveComp.WorldUp * 10.0);

				FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);

				Debug::DrawDebugLine(SwingComp.PlayerLocation, SwingComp.PlayerLocation + SwingSlope * 150.0, FLinearColor::Blue, 2.0);
				Debug::DrawDebugCoordinateSystem(Player.ActorLocation, TetherPlayerRotation, 150.0, 3.0, 0.0);
			}		
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
			SwingComp.UpdateTetherTautness(MoveComp.GetCrumbSyncedPosition().WorldVelocity);

			// Send input information to the ABP so it can play the right animations
			FVector SyncedInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
			if (SyncedInput.IsNearlyZero())
			{
				SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
			}
			else 
			{
				FVector PushDirection = Player.ActorRotation.UnrotateVector(SyncedInput);
				SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);
			}
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardSwinging");

		// Update Anim Data
		FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);
		FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());

		FVector RelativeVelocity = TetherPlayerRotation.UnrotateVector(MoveComp.Velocity);			
		SwingComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();
		SwingComp.AnimData.RelativeVelocity = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);
		SwingComp.AnimData.SwingAngle = SwingComp.SwingAngle;

		if (!SwingComp.AnimData.PushDirection.IsNearlyZero())
		{
			float Alpha = Math::Abs(SwingComp.AnimData.PushDirection.Y);
			SwingComp.AnimData.PushDirection = Math::Lerp(SwingComp.AnimData.PushDirection * 1200.0, SwingComp.AnimData.RelativeVelocity, Alpha);
		}

		// SwingComp.DebugDrawTether();
	}

	
	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (!MoveComp.PrepareMove(Movement))
	// 		return;
		
	// 	if (SwingComp.Data.bTetherTaut)
	// 		SwingComp.Data.AcceleratedTetherLength.AccelerateTo(SwingComp.Settings.TetherLength, 5.0, DeltaTime);

	// 	if (HasControl())
	// 	{
	// 		FVector MovementInput = Player.ActorRotation.RotateVector(MoveComp.MovementInput);

	// 		FVector Velocity = MoveComp.Velocity;

	// 		FVector PlayerToSwingPointDirection = SwingComp.PlayerToSwingPoint.GetSafeNormal();
	// 		FVector BiTangent = MoveComp.WorldUp.CrossProduct(PlayerToSwingPointDirection);
	// 		FVector SwingSlope = BiTangent.CrossProduct(PlayerToSwingPointDirection);				

	// 		// If our velocity is too fast, we apply drag to the overspeed part
	// 		float PreviousSpeed = Velocity.Size();
	// 		if (PreviousSpeed > SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag)
	// 		{
	// 			float Overspeed = PreviousSpeed - SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag;
	// 			Overspeed *= Math::Pow(SwingComp.Settings.OverspeedDragFactor, DeltaTime);
	// 			PreviousSpeed = SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag + Overspeed;
				
	// 			Velocity = Velocity.GetSafeNormal() * PreviousSpeed;
	// 		}

	// 		// if (MovementInput.IsNearlyZero())
	// 		{
	// 			// Player doesn't have input

	// 				/* Try a stronger gravity when you are going away from the center instead of drag
	// 						Might feel more natural
	// 					Drag should probably kick in a few seconds after input isnt pressed, so you continue the current swing you have for a bit
	// 				*/
			
	// 			Velocity *= Math::Pow(SwingComp.Settings.NoInputDragCoefficient, DeltaTime);

	// 			SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
	// 		}
	// 		// else 
	// 		// {
	// 		// 	// Player has input

	// 		// 	// Drag
	// 		// 	FVector DragDirection = MoveComp.WorldUp.CrossProduct(MovementInput).GetSafeNormal();
	// 		// 	FVector HorizontalVelocity = DragDirection * Velocity.DotProduct(DragDirection);
	// 		// 	FVector OtherVelocity = Velocity - HorizontalVelocity;

	// 		// 	HorizontalVelocity *= Math::Pow(SwingComp.Settings.HorizontalDragCoefficient, DeltaTime);
	// 		// 	OtherVelocity *= Math::Pow(SwingComp.Settings.VerticalDragCoefficient, DeltaTime);
	// 		// 	Velocity = HorizontalVelocity + OtherVelocity;

	// 		// 	// Movement Acceleration
	// 		// 	float VelocityStrength = SwingComp.Settings.InputSpeed * (SwingComp.Data.TetherLength / SwingComp.Settings.RopeLength);

	// 		// 	// Correct input in the direction of velocity
	// 		// 	if (!Velocity.IsNearlyZero())
	// 		// 	{
	// 		// 		// Correct input so that the player can hold forwards and the actual player velocity will be directed towards the direction of travel

	// 		// 		// [Attempt 1] Mirror everything - This causes LEFT and RIGHT to also flip, which is not what we want, dog
	// 		// 		// MoveInput *= Math::Sign(MovementInput.DotProduct(Velocity));

	// 		// 		// [ Attempt 2] Mirror around velocity - This was just shit. Something like this is the right direction, but it needs to not be shit
	// 		// 		// FVector FlattenedVelocityDirection = Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
	// 		// 		// float ForwardInput = FlattenedVelocityDirection.DotProduct(MoveInput);
	// 		// 		// MoveInput -= FlattenedVelocityDirection * ForwardInput;
	// 		// 		// MoveInput += FlattenedVelocityDirection * ForwardInput * Math::Sign(MovementInput.DotProduct(Velocity));
	// 		// 	}

	// 		// 	Velocity += MovementInput * VelocityStrength * DeltaTime;

	// 		// 	FVector PushDirection = Player.ActorRotation.UnrotateVector(MovementInput);
	// 		// 	SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);

	// 		// 	if(IsDebugActive())
	// 		// 		Debug::DrawDebugLine(SwingComp.PlayerLocation, SwingComp.PlayerLocation + MovementInput * 150.0, FLinearColor::Yellow, 2.0);
	// 		// }

	// 		/*	Gravity:
	// 			- If you are moving upwards, and tether not taut: Add normal vertical gravity
	// 			- Else: Add swing gravity
	// 		*/
	// 		FVector GravityAcceleration;
	// 		if (MoveComp.WorldUp.DotProduct(Velocity) > 0.0 && !SwingComp.Data.bTetherTaut)
	// 		{
	// 			GravityAcceleration = -MoveComp.WorldUp * MoveComp.GetGravityForce();
	// 		}
	// 		else
	// 		{
	// 			float GravityScale = Math::Pow(SwingSlope.Size(), 0.75);
	// 			GravityAcceleration = SwingSlope.GetSafeNormal() * GravityScale * SwingComp.Settings.GravityAcceleration;
	// 		}

	// 		// Gravity should be applied as an acceleration directly to DeltaMove so it's not framerate dependent
	// 		FVector DeltaMove = Velocity * DeltaTime;
	// 		DeltaMove += GravityAcceleration * (DeltaTime * DeltaTime * 0.5);
	// 		Velocity += GravityAcceleration * DeltaTime;

	// 		SwingComp.ConstrainVelocityToSwingPoint(Velocity, DeltaMove);

	// 		Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
	// 		Movement.AddPendingImpulses();

	// 		// Rotate Towards Input
	// 		// 		TODO: Accelerate when you have input, and decelerate when you dont.
	// 		if (ActiveDuration <= 0.3)
	// 		{
	// 			Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, InitialAttachRotation, DeltaTime, 8.0));	
	// 		}
	// 		else if (!MovementInput.IsNearlyZero())
	// 		{
	// 			FVector FacingInput = MovementInput;
	// 			FRotator CameraRotation = Player.ControlRotation;
	// 			CameraRotation.Pitch = 0.0;

	// 			float Dot = FacingInput.DotProduct(CameraRotation.ForwardVector);
	// 			if (Dot < 0.0)
	// 				FacingInput -= CameraRotation.ForwardVector * Dot * 2.0;

	// 			FRotator TargetRotation = FRotator::MakeFromXZ(FacingInput.GetSafeNormal(), MoveComp.WorldUp);
	// 			Movement.SetRotation(Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 60.0 * FacingInput.Size()));			

	// 			// Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"LeftAttach"), Player.Mesh.GetSocketLocation(n"LeftAttach") + FacingInput * 150.0, FLinearColor::Red, 2.0);
	// 		}

	// 		// Debug Draw
	// 		if (IsDebugActive())
	// 		{
	// 			SwingComp.DebugDrawVelocity(Velocity, MoveComp.WorldUp * 10.0);
	// 			SwingComp.DebugDrawGravity(GravityAcceleration, -MoveComp.WorldUp * 10.0);

	// 			FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);

	// 			Debug::DrawDebugLine(SwingComp.PlayerLocation, SwingComp.PlayerLocation + SwingSlope * 150.0, FLinearColor::Blue, 2.0);
	// 			Debug::DrawDebugCoordinateSystem(Player.ActorLocation, TetherPlayerRotation, 150.0, 3.0, 0.0);
	// 		}		
	// 	}
	// 	else
	// 	{
	// 		Movement.ApplyCrumbSyncedAirMovement();
	// 		SwingComp.UpdateTetherTautness(MoveComp.GetCrumbSyncedPosition().WorldVelocity);

	// 		// Send input information to the ABP so it can play the right animations
	// 		FVector SyncedInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
	// 		if (SyncedInput.IsNearlyZero())
	// 		{
	// 			SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
	// 		}
	// 		else 
	// 		{
	// 			FVector PushDirection = Player.ActorRotation.UnrotateVector(SyncedInput);
	// 			SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);
	// 		}
	// 	}

	// 	MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardSwinging");

	// 	// Update Anim Data
	// 	FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);
	// 	FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());

	// 	FVector RelativeVelocity = TetherPlayerRotation.UnrotateVector(MoveComp.Velocity);			
	// 	SwingComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();
	// 	SwingComp.AnimData.RelativeVelocity = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);
	// 	SwingComp.AnimData.SwingAngle = SwingComp.SwingAngle;

	// 	if (!SwingComp.AnimData.PushDirection.IsNearlyZero())
	// 	{
	// 		float Alpha = Math::Abs(SwingComp.AnimData.PushDirection.Y);
	// 		SwingComp.AnimData.PushDirection = Math::Lerp(SwingComp.AnimData.PushDirection * 1200.0, SwingComp.AnimData.RelativeVelocity, Alpha);
	// 	}

	// 	SwingComp.DebugDrawTether();
	// }
}