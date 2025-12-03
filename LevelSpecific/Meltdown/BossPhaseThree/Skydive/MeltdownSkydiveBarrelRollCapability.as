class UMeltdownSkydiveBarrelRollCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	UMeltdownSkydiveComponent SkydiveComp;
	UMeltdownSkydiveSettings Settings;
	UMovementGravitySettings GravitySettings;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	int CurrentBarrelRollDirection;
	bool bHasEverBarrelRolled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
		Settings = UMeltdownSkydiveSettings::GetSettings(Player);
		GravitySettings = UMovementGravitySettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownSkydiveBarrelRollActivatedParams& Params) const
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
	void OnActivated(FMeltdownSkydiveBarrelRollActivatedParams Params)
	{
		CurrentBarrelRollDirection = Params.BarrelRollDirection;
		SkydiveComp.AnimData.BarrelRollDirection = CurrentBarrelRollDirection;
		bHasEverBarrelRolled = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentBarrelRollDirection = 0;
		SkydiveComp.AnimData.BarrelRollDirection = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			float SkydiveHeight = SkydiveComp.CurrentSkydiveHeight;

			if(HasControl())
			{
				FVector PendingImpulse = MoveComp.GetPendingImpulse();
				FVector PendingHorizontalImpulse = PendingImpulse.VectorPlaneProject(MoveComp.WorldUp);
				CurrentHorizontalVelocity += PendingHorizontalImpulse;
				Movement.AddVelocity(PendingImpulse - PendingHorizontalImpulse);

				float Acceleration = SkydiveComp.GetAccelerationWithDrag(DeltaTime, Settings.BarrelRollDrag, Settings.BarrelRollSpeed);
				CurrentHorizontalVelocity += Player.ActorRightVector * (Acceleration * DeltaTime * CurrentBarrelRollDirection);
				CurrentHorizontalVelocity += SkydiveComp.GetFrameRateIndependentDrag(CurrentHorizontalVelocity, Settings.BarrelRollDrag, DeltaTime);
				Movement.AddVelocity(CurrentHorizontalVelocity);

				FVector CounterOrigin = Player.ViewLocation;
				FVector Delta = (Player.ActorLocation - CounterOrigin).VectorPlaneProject(FVector::UpVector);
				float Alpha = Math::GetMappedRangeValueClamped(
					FVector2D(Settings.FreeDistanceFromCenter, Settings.MaxDistanceFromCenter),
					FVector2D(0.0, 1.0),
					Delta.Size()
				);

				FVector CounterForce = -Delta.GetSafeNormal() * (Settings.HorizontalMoveSpeed * Alpha);

				if (Delta.Size() > Settings.MaxDistanceFromCenter)
					Movement.AddDeltaWithCustomVelocity(-Delta.GetSafeNormal() * (Delta.Size() - Settings.MaxDistanceFromCenter), FVector::ZeroVector);

				// Make sure we always go to the correct height
				Movement.AddDeltaWithCustomVelocity(FVector(0, 0, SkydiveHeight - Player.ActorLocation.Z), FVector(0, 0, -Settings.FallingVelocity));

				if(!CounterForce.IsNearlyZero())
					Movement.AddVelocity(CounterForce);
			}
			else
			{
				// Override the Z position so the players are always at the same height visually
				FHazeSyncedActorPosition SyncedPosition = MoveComp.GetCrumbSyncedPosition();
				SyncedPosition.WorldLocation.Z = SkydiveHeight;
				Movement.ApplyManualSyncedPosition(SyncedPosition);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"MeltdownSkydive");

#if EDITOR
				const float LineThickness = 10.0;

				FTemporalLog TemporalLog = TEMPORAL_LOG(SkydiveComp);
				TemporalLog.DirectionalArrow(f"Current Move Velocity", Player.ActorLocation, CurrentHorizontalVelocity, LineThickness, 20.0, FLinearColor::Green);
#endif
		}
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

struct FMeltdownSkydiveBarrelRollActivatedParams
{
	int BarrelRollDirection;
}