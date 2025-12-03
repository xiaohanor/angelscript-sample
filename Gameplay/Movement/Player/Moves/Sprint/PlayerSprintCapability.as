
class UPlayerSprintCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);
	default CapabilityTags.Add(PlayerSprintTags::SprintMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerStrafeComponent StrafeComp;

	float InitialSpeed = 0.0;
	float NoInputTimer = 0.0;
	FVector Direction = FVector::ZeroVector;

	bool bPerformingEnterOverspeed = false;
	float AccelerationDurationToUse = 0;
 	float AccelerationDurationModifier = 1;
	float OverspeedDelta = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		if(SprintComp.IsForcedToWalk())
			return false;

		if (SprintComp.IsForcedToSprint())
			return true;

		if (!SprintComp.IsSprintToggled())
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if(SprintComp.IsForcedToWalk())
			return true;

		if (SprintComp.IsForcedToSprint())
			return false;

		if (!SprintComp.IsSprintToggled())
			return true;

		if (NoInputTimer >= 0.06)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Sprint, this);
		InitialSpeed = MoveComp.HorizontalVelocity.Size();
		SprintComp.SetSprintActive(true);

		//Set our vertical landingspeed for animation
		FloorMotionComp.AnimData.VerticalLandingSpeed = Math::Abs(MoveComp.PreviousVerticalVelocity.Size());

		// float Angle = Math::RadiansToDegrees(MoveComp.Velocity.GetSafeNormal().AngularDistanceForNormals(Player.ActorForwardVector));
		// float HalfTurnDuration = 0.42;
		// float LerpDuration = Math::Max(Angle / 180 * HalfTurnDuration, 0.25);

		// PrintToScreen("Angle: " + Angle, Duration = 5);
		// PrintToScreen("DurationCalc: " + LerpDuration, Duration = 5);

		// Player.MeshOffsetComponent.FreezeRotationAndLerpBackToParent(this, LerpDuration);
		// if(StrafeComp.LastActiveStrafeFrame >= (Time::FrameNumber - 1) && MoveComp.HorizontalVelocity.Size() > KINDA_SMALL_NUMBER)
		// 	Player.SetActorRotation(MoveComp.HorizontalVelocity.Rotation());

		Direction = MoveComp.MovementInput.Size() > KINDA_SMALL_NUMBER ? MoveComp.MovementInput : MoveComp.HorizontalVelocity.GetSafeNormal();

		SprintComp.AnimData.bWantsToMove = false;
		NoInputTimer = 0.0;

		if(SprintComp.ShouldOverspeed())
		{
			AccelerationDurationModifier = Math::GetMappedRangeValueClamped(FVector2D(0, FloorMotionComp.Settings.MaximumSpeed), FVector2D(3, 1), InitialSpeed);
			AccelerationDurationToUse = SprintComp.Settings.OverspeedAccelerationDuration * AccelerationDurationModifier;
			OverspeedDelta = (SprintComp.Settings.MaximumSpeed + SprintComp.Settings.AdditionalActivationSpeed) - InitialSpeed;
			bPerformingEnterOverspeed = true;

			UPlayerCoreMovementEffectHandler::Trigger_SprintActivated(Player);
		}
		else
			bPerformingEnterOverspeed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Sprint, this);

		// Limit any overspeed left/etc when deactivating
		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(SprintComp.Settings.MaximumSpeed));

		SprintComp.SetSprintActive(false);
		bPerformingEnterOverspeed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Record how long we haven't had any input
		// We don't stop the sprint immediately because it might be temporarily 0 when we want a turnaround!
		if (MoveComp.MovementInput.IsNearlyZero())
			NoInputTimer += DeltaTime;
		else
			NoInputTimer = 0.0;

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetDirection = MoveComp.MovementInput;
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				FVector HorizontalVelocity;

				//We detected a grounded sprint activation and should overspeed
				if(bPerformingEnterOverspeed)
				{
					//if we somehow detect no input then exit the overspeed
					if(MoveComp.MovementInput.IsNearlyZero())
					{
						bPerformingEnterOverspeed = false;
						HorizontalVelocity = Direction.GetSafeNormal() * InitialSpeed;
					}
					else
					{
						if(ActiveDuration <= AccelerationDurationToUse)
						{
							// We are accelerating according to our acceleration curve
							HorizontalVelocity = Direction.GetSafeNormal() * ((SprintComp.SprintOverspeedAccelerationCurve.GetFloatValue(Math::Saturate(ActiveDuration / AccelerationDurationToUse)) * OverspeedDelta) + InitialSpeed);
						}
						else
						{
							//If we are done accelerating then deccelerate according to our decceleration curve
							HorizontalVelocity = Direction.GetSafeNormal() * ((SprintComp.SprintOverspeedDeccelerationCurve.GetFloatValue(
																				Math::Saturate((ActiveDuration - AccelerationDurationToUse) / SprintComp.Settings.OverspeedDeccelerationDuration)) * (SprintComp.Settings.AdditionalActivationSpeed)
																					) + CalculateTargetSpeed());
						}

						//If we have finished overspeeding according to our active duration then deactivate and return to normal sprint behavior
						if((ActiveDuration / (AccelerationDurationToUse + SprintComp.Settings.OverspeedDeccelerationDuration)) >= 1)
							bPerformingEnterOverspeed = false;
					}
				}
				else
				{
					// Calculate the target speed
					float TargetSpeed = CalculateTargetSpeed();

					if(MoveComp.MovementInput.IsNearlyZero())
						TargetSpeed = 0.0;
				
					// Update new velocity
					float InterpSpeed = SprintComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
					if(TargetSpeed < InitialSpeed)
						InterpSpeed = SprintComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
					InitialSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
					HorizontalVelocity = Direction.GetSafeNormal() * InitialSpeed;
				}
				
				// While on edges, we force the player of them.
				// if they have moved to far out on the edge,
				// and are not steering out from the edge
				if(MoveComp.HasUnstableGroundContactEdge())
				{
					bPerformingEnterOverspeed = false;

					const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
					const FVector Normal = EdgeData.EdgeNormal;
					float MoveAgainstNormal = 1 - HorizontalVelocity.GetSafeNormal().DotProduct(Normal);
					MoveAgainstNormal *= Direction.DotProductNormalized(Normal);
					float PushSpeed = Math::Clamp(HorizontalVelocity.Size(), FloorMotionComp.Settings.MinimumSpeed, SprintComp.Settings.MaximumSpeed);
					HorizontalVelocity = Math::Lerp(HorizontalVelocity, Normal * PushSpeed, MoveAgainstNormal);
				}

				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.5));

				Movement.InterpRotationToTargetFacingRotation(SprintComp.Settings.FacingDirectionInterpSpeed, false);

				// Turn off the sprint when moving to slow
				float HorizontalVelSq = MoveComp.HorizontalVelocity.SizeSquared();
				if(!bPerformingEnterOverspeed && (HorizontalVelSq < Math::Square(50.0) && MoveComp.MovementInput.Size() < 0.25))
				{
					SprintComp.SetSprintActive(false);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			SprintComp.AnimData.bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

			FName AnimTag = n"Movement";
			if (MoveComp.WasFalling())
			{
				AnimTag = n"Landing";
				UPlayerCoreMovementEffectHandler::Trigger_Landed(Player);

				FloorMotionComp.LastLandedTime = Time::GameTimeSeconds;
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	float CalculateTargetSpeed()
	{
		float SpeedAlpha = Math::Clamp((MoveComp.MovementInput.Size() - SprintComp.Settings.MinimumInput) / (1.0 - SprintComp.Settings.MinimumInput), 0.0, 1.0);
		float TargetSpeed = Math::Lerp(SprintComp.Settings.MinimumSpeed, SprintComp.Settings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

		return TargetSpeed;
	}
}