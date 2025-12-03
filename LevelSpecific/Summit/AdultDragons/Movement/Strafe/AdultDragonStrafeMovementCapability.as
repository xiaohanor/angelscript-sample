class UAdultDragonStrafeMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonStrafeComponent StrafeComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	UAdultDragonStrafeSettings StrafeSettings;

	AAdultDragonBoundarySpline BoundarySpline;

	FHazeAcceleratedFloat AccBoundaryForceMagnitude;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);

		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();

		StrafeComp.OnBeginOverlapAcidDissolveSphere.AddUFunction(this, n"OnBeginOverlapAcidDissolveSphere");
		StrafeComp.OnEndOverlapAcidDissolveSphere.AddUFunction(this, n"OnEndOverlapAcidDissolveSphere");
	}

	UFUNCTION()
	private void OnEndOverlapAcidDissolveSphere(AAcidDissolveSphere DissolveSphere)
	{
		MoveComp.RemoveMovementIgnoresActor(DissolveSphere);
	}

	UFUNCTION()
	private void OnBeginOverlapAcidDissolveSphere(AAcidDissolveSphere DissolveSphere)
	{
		MoveComp.AddMovementIgnoresActor(DissolveSphere, DissolveSphere.ActorToMaskCollision);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StrafeComp.AnimationState.Apply(EAdultDragonStormStrafeState::Flying, Player);
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Low);
		DragonComp.AimingInstigators.Add(this);

		// super ugly but this is one of the few capabilities consistently turned off when moving dragon in sequences
		DragonComp.GetAdultDragon().SetActorRelativeLocation(FVector::ZeroVector);
		DragonComp.GetAdultDragon().SetActorRelativeRotation(FRotator::ZeroRotator);

		StrafeComp.AccMovementRotation.SnapTo(Player.ActorQuat);
		AccBoundaryForceMagnitude.SnapTo(0);
		Player.ActorVelocity = Player.ActorForwardVector * StrafeSettings.ForwardMaxSpeed;
		// Player.SetActorRotation(SplineFollowManagerComp.CurrentSplineFollowData.Value.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StrafeComp.AnimationState.Clear(this);
		DragonComp.AnimationState.Clear(this);

		DragonComp.AimingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;
				FRotator InputRotation = FRotator(MovementInput.X * StrafeSettings.MaxTurningOffset.Pitch, MovementInput.Y * StrafeSettings.MaxTurningOffset.Yaw, 0);
				StrafeComp.InputRotation = InputRotation;

				InputRotation = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetWorldTransform().TransformRotation(InputRotation);
				float TurningDuration = MovementInput.IsNearlyZero() ? StrafeSettings.StrafeTurnBackDuration : StrafeSettings.StrafeTurningDuration;
				StrafeComp.AccMovementRotation.AccelerateTo(InputRotation.Quaternion(), TurningDuration, DeltaTime);

				FVector Forward = StrafeComp.AccMovementRotation.Value.ForwardVector;
				float CurrentForwardSpeed = DragonComp.GetMovementSpeed();

				float AngleSpeedChange = GetAngleSpeedChange(DeltaTime);
				CurrentForwardSpeed += AngleSpeedChange;
				CurrentForwardSpeed = Math::Clamp(CurrentForwardSpeed, StrafeSettings.ForwardMinSpeed, StrafeSettings.ForwardMaxSpeed);

				CurrentForwardSpeed *= SplineFollowManagerComp.RubberBandingMoveSpeedMultiplier;
				FVector ForwardVelocity = Forward * CurrentForwardSpeed;

				TEMPORAL_LOG(StrafeComp)
					.DirectionalArrow("Forward Velocity", Player.ActorLocation, ForwardVelocity, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Wanted Rotation", Player.ActorLocation, InputRotation.ForwardVector * 5000, 10, 40, FLinearColor::Red)
					.Value("Rubberbanding multiplier", SplineFollowManagerComp.RubberBandingMoveSpeedMultiplier);

				auto SplinePos = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();
				FVector BoundaryForce;
				float DistanceOutside = 0;
				if (BoundarySpline.GetIsOutsideBoundary(Player.ActorLocation, DistanceOutside))
				{
					float ForceMagnitude = Math::Min(DistanceOutside * 4, 13000);
					AccBoundaryForceMagnitude.AccelerateTo(ForceMagnitude, 1.0, DeltaTime);
					BoundaryForce = (SplinePos.WorldLocation - Player.ActorLocation).GetSafeNormal() * AccBoundaryForceMagnitude.Value;
					ForwardVelocity = ForwardVelocity.RotateTowards(SplinePos.WorldForwardVector, 15 * DeltaTime);
				}
				else
				{
					AccBoundaryForceMagnitude.AccelerateTo(0, 1, DeltaTime);
				}
				
				Movement.SetRotation(StrafeComp.AccMovementRotation.Value);
				FVector TargetLocation = Player.ActorLocation + (ForwardVelocity + BoundaryForce) * DeltaTime;
				Movement.AddDelta(TargetLocation - Player.ActorLocation);

				DragonComp.AnimParams.SplineRelativeDragonRotation = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetWorldTransform().InverseTransformRotation(Player.ActorRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonLocomotionTags::AdultDragonFlying);
		}
	}

	// Accelerates going downwards and decelerates going upwards
	float GetAngleSpeedChange(float DeltaTime) const
	{
		float SpeedChange = 0.0;
		float Pitch = Player.ActorRotation.Pitch;

		if (Pitch > 0)
			SpeedChange = StrafeSettings.SpeedLostGoingUp * Pitch * DeltaTime;
		else if (Pitch < 0)
			SpeedChange = StrafeSettings.SpeedGainedGoingDown * -Pitch * DeltaTime;

		return SpeedChange;
	}
};