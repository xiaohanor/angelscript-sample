class UIslandEntranceSkydiveBarrelRollCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SkydiveBarrelRoll");
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 1;

	UIslandEntranceSkydiveComponent SkydiveComp;
	UIslandEntranceSkydiveSettings Settings;
	UMovementGravitySettings GravitySettings;
	UPlayerMovementComponent MoveComp;
	UIslandEntranceSkydiveMovementData Movement;

	int CurrentBarrelRollDirection;
	bool bHasEverBarrelRolled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		Settings = UIslandEntranceSkydiveSettings::GetSettings(Player);
		GravitySettings = UMovementGravitySettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UIslandEntranceSkydiveMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandEntranceSkydiveBarrelRollActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!SkydiveComp.IsSkydiving())
			return false;

		if(bHasEverBarrelRolled && DeactiveDuration < Settings.BarrelRollCooldown)
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		float LeftStickHorizontal = GetAttributeVector2D(AttributeVectorNames::MovementRaw).Y;
		if(Math::Abs(LeftStickHorizontal) < 0.5)
			return false;

		Params.BarrelRollDirection = int(Math::Sign(LeftStickHorizontal));
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!SkydiveComp.IsSkydiving())
			return true;

		if(ActiveDuration > Settings.BarrelRollDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandEntranceSkydiveBarrelRollActivatedParams Params)
	{
		CurrentBarrelRollDirection = Params.BarrelRollDirection;
		SkydiveComp.AnimData.BarrelRollDirection = CurrentBarrelRollDirection;
		bHasEverBarrelRolled = true;
		Player.PlayForceFeedback(SkydiveComp.BarrelRollFF, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsOfClass(UMovementGravitySettings, this);
		CurrentBarrelRollDirection = 0;
		SkydiveComp.AnimData.BarrelRollDirection = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GravitySettings.GravityAmount != Settings.GravityAmount)
			UMovementGravitySettings::SetGravityAmount(Player, Settings.GravityAmount, this);

		SkydiveComp.AcceleratedTerminalVelocity.AccelerateTo(Settings.TerminalVelocity, Settings.TerminalVelocityAccelerationDuration, DeltaTime);
		UMovementGravitySettings::SetTerminalVelocity(Player, SkydiveComp.AcceleratedTerminalVelocity.Value, this);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float BarrelRollSpeedMultiplier = 1.0;
				FVector BarrelRollDirection = Player.ActorRightVector * CurrentBarrelRollDirection;

				auto BoundarySplineComp = SkydiveComp.GetCurrentBoundarySplineComponent();
				if(BoundarySplineComp != nullptr)
				{
					FVector ClosestLocation = BoundarySplineComp.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
					FVector SplineToPlayerDir = (Player.ActorLocation - ClosestLocation).GetSafeNormal();
					float BoundaryAlpha = BoundarySplineComp.GetDistanceAlphaToCenter(Player.ActorLocation);
					float PercentageOfCounterForce = Math::Saturate(BarrelRollDirection.DotProduct(SplineToPlayerDir));
					BarrelRollSpeedMultiplier = 1.0 - PercentageOfCounterForce * Math::Saturate(BoundaryAlpha);
					BarrelRollSpeedMultiplier = Math::Max(0.15, BarrelRollSpeedMultiplier);

					if(SkydiveComp.PreviousSplineClosestLocation.IsSet())
					{
						Movement.AddDelta(ClosestLocation - SkydiveComp.PreviousSplineClosestLocation.Value, EMovementDeltaType::HorizontalExclusive);
					}

					SkydiveComp.PreviousSplineClosestLocation.Set(ClosestLocation);
				}
				else
					SkydiveComp.PreviousSplineClosestLocation.Reset();

				CurrentHorizontalVelocity = Math::VInterpTo(CurrentHorizontalVelocity, BarrelRollDirection * TargetSpeed * BarrelRollSpeedMultiplier, DeltaTime, Settings.BarrelRollVelocityInterpSpeed);
				Movement.AddVelocity(CurrentHorizontalVelocity);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"IslandSkydive");

#if EDITOR
				const float LineThickness = 10.0;

				FTemporalLog TemporalLog = TEMPORAL_LOG(SkydiveComp);
				
				auto BoundarySplineComp = SkydiveComp.GetCurrentBoundarySplineComponent();
				if(BoundarySplineComp != nullptr)
				{
					FTransform ClosestTransform = BoundarySplineComp.Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
					FVector LocalPlayerLocation = ClosestTransform.InverseTransformPosition(Player.ActorLocation);
					float Alpha = BoundarySplineComp.GetLocalDistanceAlphaToCenter(LocalPlayerLocation);

					if(BoundarySplineComp.Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
					{
						float Scale = ClosestTransform.Scale3D.Z < ClosestTransform.Scale3D.Y ? ClosestTransform.Scale3D.Z : ClosestTransform.Scale3D.Y;
						TemporalLog.Circle(f"Current Boundary Circle", ClosestTransform.Location, BoundarySplineComp.BaseCylinderRadius * Scale, FRotator::MakeFromZ(ClosestTransform.Rotation.ForwardVector), FLinearColor::LucBlue, LineThickness);
					}
					else if(BoundarySplineComp.Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
					{
						FVector2D BoxExtent = FVector2D(BoundarySplineComp.BaseBoxExtent.X * ClosestTransform.Scale3D.Y, BoundarySplineComp.BaseBoxExtent.Y * ClosestTransform.Scale3D.Z);
						TemporalLog.Box(f"Current Boundary Square", ClosestTransform.Location, FVector(0.0, BoxExtent.X, BoxExtent.Y), ClosestTransform.Rotator(), FLinearColor::LucBlue, LineThickness);
					}
					else
						devError("Forgot to add case.");

					// float Acceleration = SkydiveComp.GetAccelerationWithDrag(DeltaTime, SkydiveComp.CurrentDrag, Settings.BarrelRollSpeed);
					// FVector CounterAcceleration = SkydiveComp.GetBoundarySplineCounterForce(Player.ActorLocation, Acceleration);
					// TemporalLog.Value(f"Current Target Speed", TargetSpeed);
					// TemporalLog.Value(f"Current Drag", SkydiveComp.CurrentDrag);
					// TemporalLog.Value(f"Current Boundary Alpha", Alpha);
					// TemporalLog.DirectionalArrow(f"Boundary Counter Acceleration", Player.ActorLocation, CounterAcceleration, LineThickness, 20.0, FLinearColor::Red);
				}
				
				// TemporalLog.DirectionalArrow(f"Current Horizontal Velocity", Player.ActorLocation, CurrentHorizontalVelocity, LineThickness, 20.0, FLinearColor::Green);
#endif
		}
	}

	float GetTargetSpeed() const property
	{
		float Alpha = Settings.BarrelRollSpeedCurve.GetFloatValue(ActiveDuration / Settings.BarrelRollDuration);
		Alpha = Math::Saturate(Alpha);
		return Settings.BarrelRollSpeed * Alpha;
	}

	FVector GetCurrentHorizontalVelocity() const property
	{
		return SkydiveComp.CurrentHorizontalVelocity;
	}

	void SetCurrentHorizontalVelocity(FVector Value) property
	{
		SkydiveComp.CurrentHorizontalVelocity = Value;
	}
}

struct FIslandEntranceSkydiveBarrelRollActivatedParams
{
	int BarrelRollDirection;
}