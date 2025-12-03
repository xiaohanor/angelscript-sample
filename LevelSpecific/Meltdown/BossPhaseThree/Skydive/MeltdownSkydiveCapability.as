class UMeltdownSkydiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UMeltdownSkydiveComponent SkydiveComp;
	UMeltdownSkydiveSettings Settings;
	UMovementGravitySettings GravitySettings;
	UPlayerMovementComponent MoveComp;
	UHazeCrumbSyncedVector2DComponent SyncedSkydiveAnimInput;
	USweepingMovementData Movement;
	UPlayerAimingComponent AimingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
		Settings = UMeltdownSkydiveSettings::GetSettings(Player);
		GravitySettings = UMovementGravitySettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SyncedSkydiveAnimInput = UHazeCrumbSyncedVector2DComponent::Create(Player, n"SyncedSkydiveAnimInput");
		SyncedSkydiveAnimInput.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		Movement = MoveComp.SetupSweepingMovementData();
		AimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!SkydiveComp.IsSkydiving())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMeltdownSkydiveDeactivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnWalkableGround())
		{
			Params.bBecameGroundedWalkable = true;
			return true;
		}

		if (MoveComp.IsOnAnyGround())
		{
			Params.bBecameGroundedAny = true;
			return true;
		}

		if (MoveComp.HasCustomMovementStatus(n"Swimming"))
		{
			Params.bEnteredSwimming = true;
			return true;
		}

		if(!SkydiveComp.IsSkydiving())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMeltdownSkydiveDeactivatedParams Params)
	{
		Player.ClearSettingsOfClass(UMovementGravitySettings, this);

		if(Params.bBecameGroundedAny || Params.bBecameGroundedWalkable || Params.bEnteredSwimming)
			SkydiveComp.ClearSkydivingInstigators();

		AimingComp.ClearAimingRayOverride(this);

		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			float SkydiveHeight = SkydiveComp.CurrentSkydiveHeight;

			if(HasControl())
			{
				FVector MoveDirection = MoveComp.MovementInput;
				FVector BlendSpaceValue = Player.ActorTransform.InverseTransformVector(MoveDirection);
				SyncedSkydiveAnimInput.Value = FVector2D(BlendSpaceValue.Y, BlendSpaceValue.X);

				FVector PendingImpulse = MoveComp.GetPendingImpulse();
				FVector PendingHorizontalImpulse = PendingImpulse.VectorPlaneProject(MoveComp.WorldUp);
				CurrentHorizontalVelocity += PendingHorizontalImpulse;
				Movement.AddVelocity(PendingImpulse - PendingHorizontalImpulse);

				float Acceleration = SkydiveComp.GetAccelerationWithDrag(DeltaTime, Settings.HorizontalDragFactor, Settings.HorizontalMoveSpeed);
				CurrentHorizontalVelocity += MoveComp.MovementInput * (Acceleration * DeltaTime);
				CurrentHorizontalVelocity += SkydiveComp.GetFrameRateIndependentDrag(CurrentHorizontalVelocity, Settings.HorizontalDragFactor, DeltaTime);
				Movement.AddVelocity(CurrentHorizontalVelocity);

				FVector CounterOrigin = Player.ViewLocation;
				FVector Delta = (Player.ActorLocation - CounterOrigin).VectorPlaneProject(FVector::UpVector);
				float Alpha = Math::GetMappedRangeValueClamped(
					FVector2D(Settings.FreeDistanceFromCenter, Settings.MaxDistanceFromCenter),
					FVector2D(0.0, 1.0),
					Delta.Size()
				);
				FVector CounterForce = -Delta.GetSafeNormal() * (Settings.HorizontalMoveSpeed * Alpha);

				// Stay within the radius from the center
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

			SkydiveComp.AnimData.SkydiveInput = SyncedSkydiveAnimInput.Value;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"MeltdownSkydive");

#if EDITOR
				const float LineThickness = 10.0;

				FTemporalLog TemporalLog = TEMPORAL_LOG(SkydiveComp);
				TemporalLog.DirectionalArrow(f"Current Move Velocity", Player.ActorLocation, CurrentHorizontalVelocity, LineThickness, 20.0, FLinearColor::Green);
#endif
		}
		
		FAimingRay AimingRay;
		AimingRay.Origin = Player.ActorCenterLocation;
		AimingRay.Direction = FVector::DownVector;
		AimingComp.ApplyAimingRayOverride(AimingRay, this);
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

struct FMeltdownSkydiveDeactivatedParams
{
	bool bBecameGroundedAny = false;
	bool bBecameGroundedWalkable = false;
	bool bEnteredSwimming = false;
}