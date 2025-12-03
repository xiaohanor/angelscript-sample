
class UPlayerUnwalkableSlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::UnwalkableSlide);	
	default CapabilityTags.Add(BlockedWhileIn::Perch);	

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	UPlayerUnwalkableSlideComponent UnwalkableSlideComp;
	UPlayerLandingComponent LandingComp;
	UPlayerPerchComponent PerchComp;

	const float MaxUnwalkableTime = 0.05;
	const float MaxWalkableEdgeAmountCapsulePercentage = 0.25;

	float UnwalkableGroundTime = 0.0;
	float WalkableGroundTime = 0.0;
	float SlidingEdgeTime = 0.0;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		UnwalkableSlideComp = UPlayerUnwalkableSlideComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (!MoveComp.IsOnSlidingGround())
			return false;
			
		if (PerchComp.Data.bPerching)
			return false;

		// // Code for handling going off ledges
		// if(MoveComp.IsOnWalkableGround())
		// {
		// 	const auto GroundState = MoveComp.GetGroundImpact();
		// 	const float RequiredAmount = Player.GetScaledCapsuleRadius() * MaxWalkableEdgeAmountCapsulePercentage;
		// 	if(GroundState.EdgeAmount > RequiredAmount && !GroundState.bMovingTowardsEdge)
		// 	{
		// 		return true;
		// 	}
		// }

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
			return true;

		if(WalkableGroundTime > 0.05)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::UnwalkableSlide, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Player.ActorForwardVector;

		// Transfere all the velocity to the horizontal velocity
		// so we keep the falling velocity amount, if we ended up
		// on an unwalkable surface from the air
		Player.SetActorHorizontalAndVerticalVelocity(MoveComp.Velocity, FVector::ZeroVector);

		// If we land on unwalkable ground, we start falling immediately
		if(MoveComp.WasInAir())
		{
			UnwalkableGroundTime = MaxUnwalkableTime + KINDA_SMALL_NUMBER;
		}

		// Allowing step ups while sliding can cause the player to get stuck on edges of geometry moving into the player
		UMovementSteppingSettings::SetCanTriggerStepUpOnUnwalkableSurface(Player, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::UnwalkableSlide, this);

		UnwalkableGroundTime = 0.0;
		WalkableGroundTime = 0.0;
		MoveComp.ClearMoveSpeedMultiplier(this);

		UMovementSteppingSettings::ClearCanTriggerStepUpOnUnwalkableSurface(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.IsOnWalkableGround())
		{
			UnwalkableGroundTime = 0.0;
			WalkableGroundTime += DeltaTime;
		}
		else
		{
			UnwalkableGroundTime += DeltaTime;
			WalkableGroundTime = 0.0;
		}

		float Multiplier = 1.0 - Math::Min(UnwalkableGroundTime / MaxUnwalkableTime, 1.0);
		MoveComp.ApplyMoveSpeedMultiplier(Multiplier, this);

		if(UnwalkableGroundTime >= MaxUnwalkableTime)
		{
			UnwalkableSlideComp.AnimData.bFalling = true;

			if(MoveComp.PrepareMove(Movement))	
			{
				if(HasControl())
				{
					Movement.AddOwnerHorizontalVelocity();
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
					Movement.InterpRotationToTargetFacingRotation(UnwalkableSlideComp.Settings.FacingDirectionInterpSpeed);
					Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.45));
				}
				else
				{
					Movement.ApplyCrumbSyncedAirMovement();
				}

				// Might be nice to be able to jump off the unwalkable surface. Will experiment with that, Tyko
				// if (WasActionStarted(ActionNames::MovementJump))
				// {
				// 	const FVector HorizontalGroundNormal = MoveComp.GetCurrentGroundNormal().VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
				// 	Movement.AddImpulse(HorizontalGroundNormal * 300.0);
				// }

				// TC: Should probably update to call own "UnwalkableSlide" tag
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");	
			}
		}
		else
		{
			UnwalkableSlideComp.AnimData.bFalling = false;

			if(MoveComp.PrepareMove(Movement))
			{
				if(HasControl())
				{	
					FVector TargetDirection = MoveComp.MovementInput;
					Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

					// Calculate the target speed
					float SpeedAlpha = Math::Clamp((MoveComp.MovementInput.Size() - UnwalkableSlideComp.Settings.MinimumInput) / (1.0 - UnwalkableSlideComp.Settings.MinimumInput), 0.0, 1.0);
					//float TargetSpeed = Math::Lerp(FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed, SpeedAlpha);
					float TargetSpeed = UnwalkableSlideComp.GetMovementTargetSpeed(SpeedAlpha) * MoveComp.MovementSpeedMultiplier;
					if(MoveComp.MovementInput.IsNearlyZero())
						TargetSpeed = 0.0;
				
					// Update new velocity
					float InterpSpeed = UnwalkableSlideComp.Settings.AccelerateInterpSpeed;
					if(TargetSpeed < CurrentSpeed)
						InterpSpeed = UnwalkableSlideComp.Settings.SlowDownInterpSpeed;
					CurrentSpeed = Math::FInterpTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
					FVector HorizontalVelocity = Direction * CurrentSpeed;
		
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
					Movement.AddHorizontalVelocity(HorizontalVelocity);

					// Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
					Movement.InterpRotationToTargetFacingRotation(UnwalkableSlideComp.Settings.FacingDirectionInterpSpeed);

				}
				// Remote update
				else
				{
					Movement.ApplyCrumbSyncedGroundMovement();
				}

				// TC: Should probably update to call own "UnwalkableSlide" tag
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
			}
		}	
	}
}