/**
 * Same as PlayerFloorMotion, but adds PendingImpulses with the "FloorImpulse" name
 */
class UIceLakeWindWalkGroundMovement : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 150;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerLandingComponent LandingComp;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UWindWalkComponent PlayerComp;
	UWindWalkDataComponent DataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);

		PlayerComp = UWindWalkComponent::GetOrCreate(Player);
		DataComp = UWindWalkDataComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!PlayerComp.GetIsStrongWind())
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

		if (!PlayerComp.GetIsStrongWind())
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
				FVector WindDirection = PlayerComp.GetWindDirection();

				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();
				FVector ActorForward = InputSize > KINDA_SMALL_NUMBER ? TargetDirection : Player.ActorForwardVector;

				float InputForwardAlignment = -WindDirection.DotProduct(ActorForward);
				float InputAgainstWindFactor = Math::Saturate(InputForwardAlignment);
				float InputWithWindFactor = Math::Saturate(-InputForwardAlignment);

				FVector InputRightVector = ActorForward.CrossProduct(FVector::UpVector).GetSafeNormal();
				float InputRightAlignment = -WindDirection.DotProduct(InputRightVector);

				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - FloorMotionComp.Settings.MinimumInput) / (1.0 - FloorMotionComp.Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = GetMaxSpeed(SpeedAlpha, InputForwardAlignment, InputRightAlignment);

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = FloorMotionComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = FloorMotionComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
				
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

				FVector WindForce = WindDirection * DataComp.Settings.ForceMultiplier * DeltaTime * 100;

				// Side wind force
				float SideForceFactor = Math::Abs(InputRightAlignment);
				if(SideForceFactor > KINDA_SMALL_NUMBER)
				{
					Movement.AddHorizontalVelocity(WindForce * SideForceFactor);
				}

				// Forward wind force
				if(InputSize < KINDA_SMALL_NUMBER && InputAgainstWindFactor > KINDA_SMALL_NUMBER)
				{
					Movement.AddHorizontalVelocity(WindForce * InputAgainstWindFactor);
				}

				// Back wind force
				if(InputSize < KINDA_SMALL_NUMBER && InputWithWindFactor > KINDA_SMALL_NUMBER)
				{
					Movement.AddHorizontalVelocity(WindForce * InputWithWindFactor);
				}

				// Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
				Movement.InterpRotationTo(ActorForward.ToOrientationQuat(), FloorMotionComp.Settings.FacingDirectionInterpSpeed);

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

			FName AnimTag = n"WindWalk";
			if(MoveComp.WasFalling())
				AnimTag = n"Landing";

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	private float GetMaxSpeed(float SpeedAlpha, float WindAlignmentForward, float WindAlignmentRight)
	{
		float MaxSpeed = 0.0;
		if(WindAlignmentForward > 0.0)
		{
			MaxSpeed = Math::Lerp(FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha) * MoveComp.MovementSpeedMultiplier, DataComp.Settings.AgainstWindMaxSpeed, WindAlignmentForward);
		}
		else
		{
			float WindAgainst = -WindAlignmentForward;
			MaxSpeed = Math::Lerp(FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha) * MoveComp.MovementSpeedMultiplier, FloorMotionComp.GetMovementTargetSpeed(SpeedAlpha), WindAgainst);
		}

		MaxSpeed = Math::Lerp(MaxSpeed, MaxSpeed * DataComp.Settings.SideWindMaxSpeedMultiplier, Math::Abs(WindAlignmentRight));
		return MaxSpeed;
	}
};
