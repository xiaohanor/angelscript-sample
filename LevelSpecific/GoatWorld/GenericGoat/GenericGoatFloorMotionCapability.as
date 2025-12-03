class UGenericGoatFloorMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerLandingComponent LandingComp;
	UPlayerSprintComponent SprintComp;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		// // This impulse will bring us up in the air, so dont activate
		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Player.ActorForwardVector;
		
		// FloorMotionComp.AnimData.bWantsToMove = false;

		LandingComp.AnimData.State = EPlayerLandingState::Standard;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();

				// While on edges, we force the player of them.
				if(MoveComp.HasUnstableGroundContactEdge())
				{
					const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
					const FVector Normal = EdgeData.EdgeNormal;
					float InputAgainstEdgeAlpha = TargetDirection.DotProduct(Normal);
					if(InputAgainstEdgeAlpha < 0.7)
					{
						TargetDirection = (Normal + (TargetDirection * 3)).GetSafeNormal();
						InputSize = 0.1;
					}
					else if(InputSize < 0.1)
					{
						TargetDirection = Normal;
						InputSize = 1;
					}
				}

				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha);

				// Calculate the target speed
				TargetSpeed *= MoveComp.MovementSpeedMultiplier * 1.5;

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier * 2.0;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				// Force the player of edges if we are not 
				//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

				// Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
				Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);

				if (IsDebugActive())
				{
					PrintToScreenScaled("Vel: " + Player.GetActorRotation().UnrotateVector(MoveComp.HorizontalVelocity) + " | " + Math::RoundToFloat(MoveComp.HorizontalVelocity.Size()));
					PrintToScreenScaled("SpeedAlpha: " + SpeedAlpha);
					PrintToScreenScaled("TargetSpeed: " + TargetSpeed);
				}

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = FeatureName::Movement;
			if(MoveComp.WasFalling())
			{
				AnimTag = n"Landing";
				Player.Mesh.RequestAdditiveFeature(n"LandingAdditive", this);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}


};
