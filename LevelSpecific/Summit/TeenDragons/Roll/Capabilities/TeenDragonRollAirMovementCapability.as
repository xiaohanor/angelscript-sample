class UTeenDragonRollAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 55;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	USplineLockComponent SplineLockComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		SplineLockComp = USplineLockComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsOnWalkableGround())
			return false;
		
		if(RollComp.IsForcedRolling())
		{
			return true;
		}
		else
		{
			if(!RollComp.bRollIsStarted)
				return false;
			
			if(IsActioning(RollSettings.RollInputActionName))
				return true;

			if(Time::GetGameTimeSince(RollComp.TimeLastStartedRoll) < RollSettings.RollMinDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnWalkableGround())
			return true;

		if(!RollComp.IsForcedRolling())
		{
			if(!IsActioning(RollSettings.RollInputActionName)
			&& Time::GetGameTimeSince(RollComp.TimeLastStartedRoll) > RollSettings.RollMinDuration)
				return true;
		}

		return false;
	}
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTeenDragonRollOnStartedMovingParams Params;
		Params.DragonMesh = DragonComp.DragonMesh;
		UTeenDragonRollVFX::Trigger_OnStartedMovingInAir(Player, Params);

		RollComp.TimeLastBecameAirborne = Time::GameTimeSeconds;

		RollComp.RollingInstigators.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UTeenDragonRollVFX::Trigger_OnStoppedMovingInAir(Player);

		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasAnyValidBlockingContacts())
			RollComp.RollUntilImpactInstigators.Reset();

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MovementInput = MoveComp.GetMovementInput();
				float MovementInputSize = MovementInput.Size();
				if (Math::IsNearlyZero(MovementInputSize))
					MovementInput = RollComp.PreviousMovementInput;
				else
					RollComp.PreviousMovementInput = MovementInput;
				FVector MovementInputDir = MovementInput.GetSafeNormal();

				float TurnRate = RollSettings.RollAirTurnRate;

				float ForwardSpeed = MoveComp.Velocity.DotProduct(Player.ActorForwardVector);
				if(!RollComp.bHasBeenLaunched)
				{
					if(ForwardSpeed < RollSettings.MinimumRollSpeed)
						ForwardSpeed = Math::FInterpConstantTo(ForwardSpeed, RollSettings.MinimumRollSpeed, DeltaTime, RollSettings.RollUnderSpeedAcceleration);
					else if (ForwardSpeed > RollSettings.MaximumRollSpeed)
						ForwardSpeed = Math::FInterpConstantTo(ForwardSpeed, RollSettings.MaximumRollSpeed, DeltaTime, RollSettings.RollOverSpeedDeceleration);
				}

				FVector ForwardVelocity = Player.ActorForwardVector * ForwardSpeed;
				FVector HorizontalVelocity = ForwardVelocity;

				if(DragonComp.bTopDownMode)
				{
					float HorizontalSpeed = MoveComp.HorizontalVelocity.Size();
					float SpeedAlpha = Math::NormalizeToRange(HorizontalSpeed, RollSettings.MinimumRollSpeed, RollSettings.MaximumRollSpeed);
					TurnRate = Math::Lerp(RollSettings.RollTurnRateMinSpeed, RollSettings.RollTurnRateMaxSpeed, SpeedAlpha);
				}
				else
				{
					FVector ActualMovementInput = MovementInputDir * MovementInputSize;
					FVector SidewaysVelocity = MoveComp.Velocity.ProjectOnToNormal(Player.ActorRightVector);
					FVector InputAcceleration = ActualMovementInput * RollSettings.RollSidewaysInputAcceleration * DeltaTime;
					InputAcceleration -= InputAcceleration.ProjectOnToNormal(Player.ActorForwardVector);
					SidewaysVelocity += InputAcceleration;
					SidewaysVelocity = SidewaysVelocity.GetClampedToMaxSize(RollSettings.RollSidewaysMaxSpeed);
					HorizontalVelocity += SidewaysVelocity;

					TEMPORAL_LOG(Player, "Roll Air Movement")
						.DirectionalArrow("Sideways Velocity", Player.ActorLocation, SidewaysVelocity, 20, 40, FLinearColor::Green)
					;
				}
				// Don't want to not turn when you have a spline lock
				if(!SplineLockComp.HasActiveSplineLock())
					TurnRate *= MovementInputSize;

				FVector Steering = Math::VInterpNormalRotationTo(Player.ActorForwardVector, MovementInputDir, DeltaTime, TurnRate);
				Movement.SetRotation(FRotator::MakeFromXZ(Steering, MoveComp.WorldUp));
				
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.AddHorizontalVelocity(HorizontalVelocity);

				TEMPORAL_LOG(Player, "Roll Air Movement")
					.DirectionalArrow("Forward Velocity", Player.ActorLocation, ForwardVelocity, 20, 40, FLinearColor::Red)
				;
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
};