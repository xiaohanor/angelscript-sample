
class UPlayerSwimmingUnderwaterCapability : UHazePlayerCapability
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

	UPlayerSwimmingComponent SwimmingComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UTeleportResponseComponent TPResponseComp;

	UPlayerSkydiveComponent SkydiveComp;

	const float CurrentSwimmingMinimumInputScale = 0.25;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
		TPResponseComp = UTeleportResponseComponent::GetOrCreate(Player);

		SkydiveComp = UPlayerSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SwimmingComp.InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwimmingComp.AnimData.CurrentRotation = FRotator::MakeFromXY(MoveComp.Velocity.GetSafeNormal(), Owner.ActorRightVector);

		FSwimmingEffectEventData EffectData;
		FPlayerSwimmingSurfaceData SurfaceData;
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
		else if(MoveComp.WasInAir() && !TPResponseComp.HasTeleportedWithinFrameWindow(2) && MoveComp.VerticalVelocity.Size() >= KINDA_SMALL_NUMBER)
			UPlayerSwimmingEffectHandler::Trigger_Surface_Impacted(Player, EffectData);

		if(SwimmingComp.GetState() != EPlayerSwimmingState::UnderwaterDash)
		{
			UPlayerSwimmingEffectHandler::Trigger_Underwater_Started(Player, EffectData);

			//If we somehow got redirected underwater by surface dash then call surface stopped as a failsafe to remove Surface effects
			if(SwimmingComp.GetState() == EPlayerSwimmingState::SurfaceDash)
				UPlayerSwimmingEffectHandler::Trigger_Surface_Stopped(Player, EffectData);
		}

		if(SwimmingComp.State != EPlayerSwimmingState::UnderwaterDash && SwimmingComp.UnderwaterCamSettings != nullptr)
		{
			Player.ClearCameraSettingsByInstigator(SwimmingComp);
			Player.ApplyCameraSettings(SwimmingComp.UnderwaterCamSettings, 5, SwimmingComp);
		}

		if(SwimmingComp.GetState() != EPlayerSwimmingState::ApexDive)
			SwimmingComp.SetState(EPlayerSwimmingState::Underwater);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;
		
		if(SwimmingComp.AnimData.State != EPlayerSwimmingState::UnderwaterDash)
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
				
				// Wooo Ylva's ugly "temp" hack!
				bool bMovementDisabled = Player.IsCapabilityTagBlocked(PlayerSwimmingTags::SwimmingUnderwaterInput);
				if (bMovementDisabled)
					RawMoveInput2D = FVector2D();
				FVector RawMoveInput = FVector(RawMoveInput2D.X, RawMoveInput2D.Y, 0.0);

				FVector Velocity = MoveComp.Velocity;
				FVector MoveDirection;

				//If we just entered underwaterSwimming then dont allow swimming upwards, this prevent surface flickering if holding jump + Entering water with just enough vertical velocity to bypass surface swimming
				bool bSwimmingUp = ActiveDuration >= 0.5 && (!bMovementDisabled && IsActioning(ActionNames::MovementVerticalUp));
				bool bSwimmingDown = !bMovementDisabled && IsActioning(ActionNames::MovementVerticalDown);

				if (SwimmingComp.Settings.bCurrentSwimmingEnabled || PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
				{
					// When in CurrentSwimming or sidescroller movement, we want to swim up or down with the stick
					MoveDirection = Player.ViewRotation.RotateVector(FVector(
						0.0, RawMoveInput2D.Y, RawMoveInput2D.X,
					));

					if (SwimmingComp.Settings.bCurrentSwimmingEnabled)
					{
						float VerticalScale = 0.0;
						if (bSwimmingUp)
							VerticalScale += 1.5;
						if (bSwimmingDown)
							VerticalScale -= 1.5;
						
						MoveDirection.Z += VerticalScale;

						//Remap our Input into our deadzone range + take deadzone size into consideration for top end value of the opposite axis
						//(even if we arent hitting precisely straight up for vertical, aslong as we are in the horizontal deadzone we want to get full vertical effect)

						MoveDirection.Z = Math::GetMappedRangeValueClamped(FVector2D(CurrentSwimmingMinimumInputScale, 1 - CurrentSwimmingMinimumInputScale), FVector2D(0, 1), Math::Abs(MoveDirection.Z)) * Math::Sign(MoveDirection.Z);
						MoveDirection.X = Math::GetMappedRangeValueClamped(FVector2D(CurrentSwimmingMinimumInputScale, 1 - CurrentSwimmingMinimumInputScale), FVector2D(0, 1), Math::Abs(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X)) * -Math::Sign(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X);

						SwimmingComp.AnimData.VerticalMovementScale = Math::GetMappedRangeValueClamped(FVector2D(-1.5, 1.5), FVector2D(-1, 1), VerticalScale);
						SwimmingComp.AnimData.CurrentSwimmingMovementScale.Y = MoveDirection.Z;
						SwimmingComp.AnimData.CurrentSwimmingMovementScale.X = -MoveDirection.X;
					}
					else
					{
						SwimmingComp.AnimData.VerticalMovementScale = MoveDirection.DotProduct(MoveComp.WorldUp);
					}
				}
				else
				{
					// In 3D or topdown movement, use separate input for up and down
					float VerticalScale = 0.0;
					if (bSwimmingUp)
						VerticalScale += 1.5;
					if (bSwimmingDown)
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

				if (SwimmingComp.Settings.bCurrentSwimmingEnabled)
					TargetRotation.Yaw = Player.ViewRotation.Yaw;
				
				FRotator Rotation;
				if(SwimmingComp.Settings.bUseConstantInterpRotationUnderwater)
					Rotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, SwimmingComp.Settings.InterpRotationSpeedUnderwater);
				else
					Rotation = Math::RInterpTo(Owner.ActorRotation, TargetRotation, DeltaTime, SwimmingComp.Settings.InterpRotationSpeedUnderwater);
				
				Movement.SetRotation(Rotation);

				SwimmingComp.AnimData.MovementScale = MoveDirection.Size();
				SwimmingComp.AnimData.WantedDirection = MoveDirection.GetSafeNormal();
				SwimmingComp.AnimData.CurrentDirection = Velocity.GetSafeNormal();

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

			if(SwimmingComp.GetState() == EPlayerSwimmingState::ApexDive && ActiveDuration >= 0.3)
				SwimmingComp.SetState(EPlayerSwimmingState::Underwater);

			//Block ground traces to make sure we arent redirected along the ground by solver
			Movement.BlockGroundTracingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, SwimmingComp.Settings.bCurrentSwimmingEnabled ? n"CurrentSwimming" :  n"UnderwaterSwimming");
		}
	}
}