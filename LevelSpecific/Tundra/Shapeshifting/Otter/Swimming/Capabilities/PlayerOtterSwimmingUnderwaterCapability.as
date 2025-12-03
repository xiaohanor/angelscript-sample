
class UTundraPlayerOtterSwimmingUnderwaterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingUnderwater);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UPlayerSkydiveComponent SkydiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);

		SkydiveComp = UPlayerSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() != ETundraPlayerOtterSwimmingActiveState::Active)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (SwimmingComp.InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwimmingComp.AnimData.CurrentRotation = FRotator::MakeFromXY(MoveComp.Velocity.GetSafeNormal(), Owner.ActorRightVector);

		FSwimmingEffectEventData EffectData;
		FTundraPlayerOtterSwimmingSurfaceData SurfaceData;
		if(SwimmingComp.CheckForSurface(Player,SurfaceData))
		{
			EffectData.SurfaceLocation = SurfaceData.SurfaceLocation;
		}
		else
		{
			//Incase we didnt find a valid surface we use the top of the player instead of spawning on old locations/zero vectors
			EffectData.SurfaceLocation = Player.ActorLocation + (MoveComp.WorldUp * Player.ScaledCapsuleHalfHeight);
		}

		if(SkydiveComp.IsSkydiveActive())
			UPlayerSwimmingEffectHandler::Trigger_Surface_SkydiveImpacted(Player, EffectData);
		
		if(SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::UnderwaterDash)
			UPlayerSwimmingEffectHandler::Trigger_Underwater_Started(Player, EffectData);

		if(SwimmingComp.GetCurrentState() != ETundraPlayerOtterSwimmingState::UnderwaterDash && SwimmingComp.UnderwaterCamSettings != nullptr)
		{
			Player.ClearCameraSettingsByInstigator(SwimmingComp);
			Player.ApplyCameraSettings(SwimmingComp.UnderwaterCamSettings, 5, SwimmingComp);
		}

		SwimmingComp.SetCurrentState(ETundraPlayerOtterSwimmingState::Underwater);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;
		
		if(SwimmingComp.CurrentState != ETundraPlayerOtterSwimmingState::UnderwaterDash)
			UPlayerSwimmingEffectHandler::Trigger_Underwater_Stopped(Player, Data);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector2D RawMoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector RawMoveInput = FVector(RawMoveInput2D.X, RawMoveInput2D.Y, 0.0);

				FVector Velocity = MoveComp.Velocity;
				FVector MoveDirection;

				if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
				{
					// When in sidescroller movement, we want to swim up or down with the stick
					MoveDirection = Player.ViewRotation.RotateVector(FVector(
						0.0, RawMoveInput2D.Y, RawMoveInput2D.X,
					));

					float VerticalScale = 0.0;
					if (IsActioning(ActionNames::MovementVerticalUp))
						VerticalScale += 1.5;
					if (IsActioning(ActionNames::MovementVerticalDown))
						VerticalScale -= 1.5;

					MoveDirection.Z += VerticalScale;
					SwimmingComp.AnimData.VerticalMovementScale = Math::Clamp(MoveDirection.DotProduct(MoveComp.WorldUp), -1, 1);
				}
				else
				{
					// In 3D or topdown movement, use separate input for up and down
					float VerticalScale = 0.0;
					if (IsActioning(ActionNames::MovementVerticalUp))
						VerticalScale += 1.5;
					if (IsActioning(ActionNames::MovementVerticalDown))
						VerticalScale -= 1.5;

					SwimmingComp.AnimData.VerticalMovementScale = Math::GetMappedRangeValueClamped(FVector2D(-1.5, 1.5), FVector2D(-1, 1), VerticalScale);
					MoveDirection = Player.ViewRotation.RotateVector(RawMoveInput) + (MoveComp.WorldUp * VerticalScale);
				}

				MoveDirection = MoveDirection.GetClampedToMaxSize(1.0);

				// Overspeed drag
				if (Velocity.Size() > SwimmingComp.Settings.UnderwaterDesiredSpeed)
				{
					Velocity *= Math::Pow(0.08, DeltaTime);
					if (Velocity.Size() < SwimmingComp.Settings.UnderwaterDesiredSpeed)
						Velocity = Velocity.GetSafeNormal() * SwimmingComp.Settings.UnderwaterDesiredSpeed;
				}

				FVector TargetVelocity = MoveDirection * SwimmingComp.Settings.UnderwaterDesiredSpeed;

				//Enforce a minimum speed if giving input
				if(!MoveDirection.IsNearlyZero() && TargetVelocity.Size() < SwimmingComp.Settings.UnderwaterMinimumSpeed)
					TargetVelocity = TargetVelocity.GetSafeNormal() * SwimmingComp.Settings.UnderwaterMinimumSpeed;

				Velocity = Math::VInterpTo(Velocity, TargetVelocity, DeltaTime, SwimmingComp.Settings.UnderwaterDesiredSpeedInterpSpeed);

				Movement.AddVelocity(Velocity);			
				Movement.AddPendingImpulses();

				// Rotate Player
				FRotator TargetRotation = Owner.ActorRotation;

				FVector HorizontalMoveDirection = MoveDirection.ConstrainToPlane(MoveComp.WorldUp);
				if (!HorizontalMoveDirection.IsNearlyZero())
				{
					TargetRotation = FRotator::MakeFromXZ(HorizontalMoveDirection, MoveComp.WorldUp);
					TargetRotation.Pitch = 0.0;
				}
				
				FRotator Rotation;
				if(SwimmingComp.Settings.bUseConstantInterpRotationUnderwater)
					Rotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, SwimmingComp.Settings.InterpRotationSpeedUnderwater);
				else
					Rotation = Math::RInterpTo(Owner.ActorRotation, TargetRotation, DeltaTime, SwimmingComp.Settings.InterpRotationSpeedUnderwater);
				
				Movement.SetRotation(Rotation);

				SwimmingComp.AnimData.MovementScale = MoveDirection.Size();
				SwimmingComp.AnimData.WantedDirection = MoveDirection.GetSafeNormal();
				SwimmingComp.AnimData.CurrentDirection = Velocity.GetSafeNormal();

				/*
					This isn't right, but moving on for now. Submitting so animators have 'something' to hook up.
				*/
				// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, SwimmingComp.AnimData.CurrentRotation.ForwardVector, 200.0, LineColor = FLinearColor::Red);
				// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, SwimmingComp.AnimData.CurrentRotation.RightVector, 50.0, LineColor = FLinearColor::Green);
				// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, SwimmingComp.AnimData.CurrentRotation.UpVector, 50.0, LineColor = FLinearColor::Blue);

				if (!MoveDirection.IsNearlyZero())
				{
					FRotator WantedRotation = FRotator::MakeFromAxes(MoveDirection, Owner.ActorRightVector, MoveComp.WorldUp);
					// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, WantedRotation.ForwardVector, 100.0, LineColor = FLinearColor::Red);
					// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, WantedRotation.RightVector, 25.0, LineColor = FLinearColor::Green);
					// Debug::DrawDebugDirectionArrow(Owner.ActorCenterLocation, WantedRotation.UpVector, 25.0, LineColor = FLinearColor::Blue);

					SwimmingComp.AnimData.CurrentRotation = Math::RInterpConstantTo(SwimmingComp.AnimData.CurrentRotation, WantedRotation, DeltaTime, 200.0);
					//FRotator RotationDelta = WantedRotation - SwimmingComp.AnimData.CurrentRotation;
					//PrintToScreenScaled("RotationDelta: " + RotationDelta );
				}	

				Player.ApplyMovementInput(MoveDirection, this, EInstigatePriority::Normal);

			}
			else
			{
				FVector MoveDirection = MoveComp.SyncedMovementInputForAnimationOnly;
				SwimmingComp.AnimData.MovementScale = MoveDirection.Size();
				SwimmingComp.AnimData.WantedDirection = MoveDirection.GetSafeNormal();
				SwimmingComp.AnimData.CurrentDirection = MoveComp.Velocity.GetSafeNormal();
				
				Movement.ApplyCrumbSyncedAirMovement();
			}			

			//FTransform TransformTest(FRotator::MakeFromXY(SwimmingComp.AnimData.CurrentDirection, TargetRotation.RightVector));
			
			//FVector ToWanted = SwimmingComp.AnimData.WantedDirection - SwimmingComp.AnimData.CurrentDirection;
			//FVector Test = TransformTest.InverseTransformVector(SwimmingComp.AnimData.WantedDirection);

			//PrintToScreenScaled("ToWanted: " + Test );

			//Block ground traces to make sure we arent redirected along the ground by solver
			Movement.BlockGroundTracingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"UnderwaterSwimming");
		}
	}
}