class UPlayerAutoRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder+1;

	UPlayerMovementComponent MoveComp;
	UPlayerAutoRunComponent AutoRunComp;
	UPlayerSprintComponent SprintComp;

	bool bIsSprinting = false;
	bool bAppliedInitialVelocity = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AutoRunComp = UPlayerAutoRunComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AutoRunComp.ActiveAutoRun.IsDefaultValue())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AutoRunComp.ActiveAutoRun.IsDefaultValue())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bAppliedInitialVelocity = false;

		const FActiveAutoRun& AutoRun = AutoRunComp.ActiveAutoRun.Get();
		if (AutoRun.Settings.bSprint)
		{
			bIsSprinting = true;
			SprintComp.ForceSprint(this);
		}
		else
		{
			bIsSprinting = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bIsSprinting)
			SprintComp.SetSprintToggled(true);
		SprintComp.ClearForceSprint(this);
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FActiveAutoRun& AutoRun = AutoRunComp.ActiveAutoRun.Get();
		FInstigator Instigator = AutoRunComp.ActiveAutoRun.GetCurrentInstigator();

		// Cancel when the player gives input
		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if (AutoRun.Settings.bCancelOnPlayerInput && RawStick.Size() > 0.1)
		{
			AutoRunComp.ActiveAutoRun.Clear(Instigator);
			return;
		}

		// Cancel when the duration expires
		if (AutoRun.Settings.CancelAfterDuration > 0.0 && ActiveDuration >= AutoRun.Settings.CancelAfterDuration)
		{
			AutoRunComp.ActiveAutoRun.Clear(Instigator);
			return;
		}

		// Give input in the auto-run direction
		float WantedSpeed = 1.0;
		FVector WantedMovement;

		if (AutoRun.Settings.CancelAfterDuration > 0.0 && AutoRun.Settings.bSlowDownAtEnd && ActiveDuration >= AutoRun.Settings.CancelAfterDuration - 2.0)
		{
			WantedSpeed = Math::Min(
				WantedSpeed,
				(AutoRun.Settings.CancelAfterDuration - ActiveDuration) / 2.0
			);
		}

		if (AutoRun.Spline != nullptr)
		{
			float SplineDistance = AutoRun.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
			WantedMovement = AutoRun.Spline.GetWorldRotationAtSplineDistance(SplineDistance).ForwardVector;
			WantedMovement = WantedMovement.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			// Slow down near the end of the spline
			float RemainingDistance = AutoRun.Spline.SplineLength - SplineDistance;
			if (RemainingDistance <= KINDA_SMALL_NUMBER)
			{
				AutoRunComp.ActiveAutoRun.Clear(Instigator);
				return;
			}
			else if (AutoRun.Settings.bSlowDownAtEnd)
			{
				if (RemainingDistance <= 800.0)
				{
					SprintComp.ClearForceSprint(this);
					bIsSprinting = false;
					WantedSpeed = Math::Min(WantedSpeed, RemainingDistance / 800.0);
				}
			}
		}
		else
		{
			WantedMovement = AutoRun.StaticDirection.GetSafeNormal();
			WantedMovement = WantedMovement.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		}

		// Apply any slowdown we created
		WantedMovement = WantedMovement * WantedSpeed;

		// Apply deviation if we have it
		if (!AutoRun.Settings.bCancelOnPlayerInput && AutoRun.Settings.MaxMovementDeviationAngle > 0.0)
		{
			const FVector Up = MoveComp.GetWorldUp();
			const FRotator ControlRotation = Player.GetControlRotation();
			FVector Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
			FVector Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);

			FVector InputMovementDirection = Forward * RawStick.X + Right * RawStick.Y;
			InputMovementDirection = InputMovementDirection.GetSafeNormal();
			if (InputMovementDirection.Size() > 0.1)
			{
				float AngularDistance = InputMovementDirection.AngularDistance(WantedMovement);
				if (AngularDistance > 0.0)
				{
					float AllowedPct = Math::Min(Math::DegreesToRadians(AutoRun.Settings.MaxMovementDeviationAngle) / AngularDistance, 1.0);

					FQuat AutoRotation = FQuat::MakeFromX(WantedMovement);
					FQuat InputRotation = FQuat::MakeFromX(InputMovementDirection);
					FQuat FinalRotation = FQuat::Slerp(AutoRotation, InputRotation, AllowedPct);
					WantedMovement = FinalRotation.ForwardVector * WantedMovement.Size();
				}
			}
		}

		// Apply input magnitude if we've changed it
		if (AutoRun.Settings.InputMagnitude < 1.0)
			WantedMovement *= AutoRun.Settings.InputMagnitude;

		// Apply the initial velocity if we've specified one
		if (!bAppliedInitialVelocity && !WantedMovement.IsNearlyZero())
		{
			float ExistingVelocity = Player.ActorHorizontalVelocity.Size();
			if (ExistingVelocity < AutoRun.Settings.MinimumInitialVelocity)
			{
				Player.SetActorHorizontalVelocity(
					WantedMovement.GetSafeNormal() * AutoRun.Settings.MinimumInitialVelocity
				);
			}

			bAppliedInitialVelocity = true;
		}

		// Force the movement input in a direction
		Player.ApplyMovementInput(WantedMovement, this, EInstigatePriority::High);
	}
};