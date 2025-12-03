
class UPlayerFloorMotionCapability : UHazePlayerCapability
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
		Direction = MoveComp.MovementInput.Size() > KINDA_SMALL_NUMBER ? MoveComp.MovementInput : MoveComp.HorizontalVelocity.GetSafeNormal();

		//Set our vertical landingspeed for animation
		FloorMotionComp.AnimData.VerticalLandingSpeed = Math::Abs(MoveComp.PreviousVerticalVelocity.Size());
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
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha);

				// Calculate the target speed
				TargetSpeed *= MoveComp.MovementSpeedMultiplier;

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;

				// While on edges, we force the player of them.
				// if they have moved to far out on the edge,
				// and are not steering out from the edge
				// We wait one frame with applying this, as we want our own UnstableDistance to kick in
				if(MoveComp.HasUnstableGroundContactEdge() && ActiveDuration > KINDA_SMALL_NUMBER)
				{
					const FMovementEdge EdgeData = MoveComp.GroundContact.EdgeResult;
					const FVector Normal = EdgeData.EdgeNormal;
					float MoveAgainstNormal = 1 - HorizontalVelocity.GetSafeNormal().DotProduct(Normal);
					MoveAgainstNormal *= Direction.DotProductNormalized(Normal);
					float PushSpeed = Math::Clamp(HorizontalVelocity.Size(), FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed);
					HorizontalVelocity = Math::Lerp(HorizontalVelocity, Normal * PushSpeed, MoveAgainstNormal);
				}
	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.25));

				// Force the player of edges if we are not 
				// Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

				// Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
				Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed, false);

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
			if (MoveComp.WasFalling())
			{
				AnimTag = n"Landing";

				UPlayerCoreMovementEffectHandler::Trigger_Landed(Player);
				FloorMotionComp.LastLandedTime = Time::GameTimeSeconds;
			}
			// else if(bIdling)
			// {
			// 	AnimTag = n"AFKIdle";
			// }

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
};
