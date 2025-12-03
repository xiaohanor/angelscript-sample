class UIslandEntranceSkydiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;

	UIslandEntranceSkydiveComponent SkydiveComp;
	UIslandEntranceSkydiveSettings Settings;
	UMovementGravitySettings GravitySettings;
	UPlayerMovementComponent MoveComp;
	UHazeCrumbSyncedVector2DComponent SyncedSkydiveAnimInput;
	UIslandEntranceSkydiveMovementData Movement;

	float OldSkydiveLocationZ;
	float OldSkydiveVerticalVelocity;
	float AccelerationDistance;
	float PreviousDiscrepancy = 0.0;

	USceneComponent FallHeightComponent;
	USceneComponent OtherPlayerFallHeightComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		Settings = UIslandEntranceSkydiveSettings::GetSettings(Player);
		GravitySettings = UMovementGravitySettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SyncedSkydiveAnimInput = UHazeCrumbSyncedVector2DComponent::Create(Player, n"SyncedSkydiveAnimInput");
		SyncedSkydiveAnimInput.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		Movement = MoveComp.SetupMovementData(UIslandEntranceSkydiveMovementData);

		FallHeightComponent = USceneComponent::GetOrCreate(Player, n"IslandSkydiveFallHeightComponent");
		FallHeightComponent.SetAbsolute(true, true, true);
		FallHeightComponent.SetWorldLocation(FVector(0, 0, 0));

		OtherPlayerFallHeightComponent = USceneComponent::GetOrCreate(Player.OtherPlayer, n"IslandSkydiveFallHeightComponent");
		OtherPlayerFallHeightComponent.SetAbsolute(true, true, true);
		OtherPlayerFallHeightComponent.SetWorldLocation(FVector(0, 0, 0));
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
	bool ShouldDeactivate(FIslandEntranceSkydiveDeactivatedParams& Params) const
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
		if(SkydiveComp.bActivatedFromCutscene)
		{
			Player.SetActorVerticalVelocity(FVector::DownVector * 1600.0);
			// This gravity amount seems to be closest to get 0 discrepancy between old skydive and new skydive.
			UMovementGravitySettings::SetGravityAmount(Player, 309.09, SkydiveComp, EHazeSettingsPriority::Final);
			OldSkydiveLocationZ = Player.ActorLocation.Z;
			SkydiveComp.bOverrideGravity = true;
			SkydiveComp.bActivatedFromCutscene = false;
		}

		if (Network::IsGameNetworked() && HasControl() && Settings.bSyncRelativeToFallHeight)
		{
			MoveComp.ApplyCrumbSyncedRelativePosition(this, FallHeightComponent);

			FallHeightComponent.SetWorldLocation(FVector(0, 0, Player.ActorLocation.Z));
			OtherPlayerFallHeightComponent.SetWorldLocation(FVector(0, 0, Player.ActorLocation.Z));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FIslandEntranceSkydiveDeactivatedParams Params)
	{
		Player.ClearSettingsOfClass(UMovementGravitySettings, this);

		if(Params.bBecameGroundedAny || Params.bBecameGroundedWalkable || Params.bEnteredSwimming)
		{
			SkydiveComp.ClearSkydivingInstigators();
		}

		MoveComp.ClearCrumbSyncedRelativePosition(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GravitySettings.GravityAmount != Settings.GravityAmount)
			UMovementGravitySettings::SetGravityAmount(Player, Settings.GravityAmount, this);

		if(SkydiveComp.bOverrideGravity && Math::IsNearlyEqual(Math::Abs(MoveComp.VerticalSpeed), Settings.TerminalVelocity))
		{
			SkydiveComp.ClearGravityAudioSyncOverride();
		}

		SkydiveComp.AcceleratedTerminalVelocity.AccelerateTo(Settings.TerminalVelocity, Settings.TerminalVelocityAccelerationDuration, DeltaTime);
		UMovementGravitySettings::SetTerminalVelocity(Player, SkydiveComp.AcceleratedTerminalVelocity.Value, this);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MoveDirection = MoveComp.MovementInput;
				FVector BlendSpaceValue = Player.ActorTransform.InverseTransformVector(MoveDirection);
				SyncedSkydiveAnimInput.Value = FVector2D(BlendSpaceValue.Y, BlendSpaceValue.X);

				FVector PendingImpulse = MoveComp.GetPendingImpulse();
				FVector PendingHorizontalImpulse = PendingImpulse.VectorPlaneProject(MoveComp.WorldUp);
				CurrentHorizontalVelocity += PendingHorizontalImpulse;
				Movement.AddVelocity(PendingImpulse - PendingHorizontalImpulse);

				float Acceleration = SkydiveComp.GetAccelerationWithDrag(DeltaTime, Settings.DragFactor, Settings.HorizontalMoveSpeed);
				CurrentHorizontalVelocity += MoveComp.MovementInput * (Acceleration * DeltaTime);
				
				FVector CounterAcceleration = SkydiveComp.GetBoundarySplineCounterForce(Player.ActorLocation, Acceleration);
				CurrentHorizontalVelocity += CounterAcceleration * DeltaTime;

				CurrentHorizontalVelocity += SkydiveComp.GetFrameRateIndependentDrag(CurrentHorizontalVelocity, Settings.DragFactor, DeltaTime);
				Movement.AddVelocity(CurrentHorizontalVelocity);

				auto BoundarySplineComp = SkydiveComp.GetCurrentBoundarySplineComponent();
				if(BoundarySplineComp != nullptr)
				{
					FVector ClosestLocation = BoundarySplineComp.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
					if(SkydiveComp.PreviousSplineClosestLocation.IsSet())
					{
						Movement.AddDelta(ClosestLocation - SkydiveComp.PreviousSplineClosestLocation.Value, EMovementDeltaType::HorizontalExclusive);
					}

					SkydiveComp.PreviousSplineClosestLocation.Set(ClosestLocation);
				}
				else
					SkydiveComp.PreviousSplineClosestLocation.Reset();

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			PreviousDiscrepancy = GetDiscrepancyBetweenOldLocationAndCurrent();

			SkydiveComp.AnimData.SkydiveInput = SyncedSkydiveAnimInput.Value;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"IslandSkydive");

			{
				const float Acceleration = -2385.0;
				const float TerminalVelocity = -2500.0;

				OldSkydiveVerticalVelocity += Acceleration * DeltaTime * 0.5;
				OldSkydiveVerticalVelocity = Math::Max(TerminalVelocity, OldSkydiveVerticalVelocity);
				float Delta = OldSkydiveVerticalVelocity * DeltaTime;
				OldSkydiveVerticalVelocity += Acceleration * DeltaTime * 0.5;
				OldSkydiveVerticalVelocity = Math::Max(TerminalVelocity, OldSkydiveVerticalVelocity);
				
				OldSkydiveLocationZ += Delta;
			}

#if EDITOR
				const float LineThickness = 10.0;

				FTemporalLog TemporalLog = TEMPORAL_LOG(SkydiveComp);
				TEMPORAL_LOG(this).Value("bOverrideGravity", SkydiveComp.bOverrideGravity);
				TEMPORAL_LOG(this).Value("Vertical Speed", MoveComp.VerticalSpeed);
				TEMPORAL_LOG(this).Value("OldSkydiveVerticalVelocity", OldSkydiveVerticalVelocity);
				TEMPORAL_LOG(this).Point("PlayerLocation", Player.ActorLocation, 15.f, FLinearColor::Green);
				TEMPORAL_LOG(this).Point("PlayerLocation Before Snap Velocity", FVector(Player.ActorLocation.X, Player.ActorLocation.Y, OldSkydiveLocationZ), 15.f, FLinearColor::Red);
				TEMPORAL_LOG(this).Value("Discrepancy", GetDiscrepancyBetweenOldLocationAndCurrent());
				TEMPORAL_LOG(this).Value("Discrepancy Direction", Math::Sign(GetDiscrepancyBetweenOldLocationAndCurrent() - PreviousDiscrepancy));
				
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

					float Acceleration = SkydiveComp.GetAccelerationWithDrag(DeltaTime, Settings.DragFactor, Settings.HorizontalMoveSpeed);
					FVector CounterAcceleration = SkydiveComp.GetBoundarySplineCounterForce(Player.ActorLocation, Acceleration);
					TemporalLog.Value(f"Current Boundary Alpha", Alpha);
					TemporalLog.Value(f"Current Target Speed", Settings.HorizontalMoveSpeed);
					TemporalLog.Value(f"Current Drag", Settings.DragFactor);
					TemporalLog.DirectionalArrow(f"Boundary Counter Acceleration", Player.ActorLocation, CounterAcceleration, LineThickness, 20.0, FLinearColor::Red);
				}
				
				TemporalLog.DirectionalArrow(f"Current Horizontal Velocity", Player.ActorLocation, CurrentHorizontalVelocity, LineThickness, 20.0, FLinearColor::Green);
#endif
		}

		if (Network::IsGameNetworked() && HasControl() && Settings.bSyncRelativeToFallHeight)
		{
			FallHeightComponent.SetWorldLocation(FVector(0, 0, Player.ActorLocation.Z));
			OtherPlayerFallHeightComponent.SetWorldLocation(FVector(0, 0, Player.ActorLocation.Z));
		}
	}

	float GetDiscrepancyBetweenOldLocationAndCurrent() const
	{
		return Player.ActorLocation.Z - OldSkydiveLocationZ;
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

struct FIslandEntranceSkydiveDeactivatedParams
{
	bool bBecameGroundedAny = false;
	bool bBecameGroundedWalkable = false;
	bool bEnteredSwimming = false;
}