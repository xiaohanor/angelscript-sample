struct FPigSiloMovementCapabilityActivationParams
{
	UHazeSplineComponent Spline = nullptr;
}

class UPigSiloMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;
	default DebugCategory = PigTags::Pig;

	UPlayerPigSiloComponent PigSiloComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UPigSiloMovementSettings MovementSettings;

	FSplinePosition SplinePosition;

	FVector AcceleratedRelativeMeshLocation;
	FQuat AcceleratedMeshRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSweepingMovementData();
		MovementSettings = UPigSiloMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPigSiloMovementCapabilityActivationParams& ActivationParams) const
	{
		if (!PigSiloComponent.IsSiloMovementActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (MovementComponent.HasUpwardsImpulse())
			return false;

		ActivationParams.Spline = PigSiloComponent.CurrentSpline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PigSiloComponent.IsSiloMovementActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPigSiloMovementCapabilityActivationParams ActivationParams)
	{
		PigSiloComponent.CurrentSpline = ActivationParams.Spline;

		float DistanceAlongSpline = PigSiloComponent.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		SplinePosition = FSplinePosition(PigSiloComponent.CurrentSpline, DistanceAlongSpline, true);

		AcceleratedRelativeMeshLocation = Player.MeshOffsetComponent.RelativeLocation;
		AcceleratedMeshRotation = Player.ActorQuat;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(PigTags::SpecialAbility, this);

		//Audio
		UPigRainbowFartEffectEventHandler::Trigger_OnSlideStarted(Player);
		UStretchyPigEffectEventHandler::Trigger_OnSlideStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.1);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(PigTags::SpecialAbility, this);

		//Audio
		UPigRainbowFartEffectEventHandler::Trigger_OnSlideStopped(Player);
		UStretchyPigEffectEventHandler::Trigger_OnSlideStopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				MoveData.IgnoreActorForThisFrame(SplinePosition.CurrentSpline.Owner);

				float SplineMoveDelta = MovementSettings.CurrentMoveSpeed * DeltaTime;
				SplinePosition.Move(SplineMoveDelta);

				// Did we move to next spline?
				if (PigSiloComponent.CurrentSpline != SplinePosition.CurrentSpline)
					PigSiloComponent.Crumb_SetCurrentSpline(SplinePosition.CurrentSpline);

				FVector MoveDelta = SplinePosition.GetWorldLocation() - Player.ActorLocation;
				MoveDelta += SplinePosition.GetWorldRightVector() * PigSiloComponent.SiloPlatform.GetHorizontalOffsetForPlayer(Player);

				MoveData.AddDelta(MoveDelta);

				// MoveData.AddOwnerVerticalVelocity();
				// MoveData.AddGravityAcceleration();

				MoveData.SetRotation(SplinePosition.WorldForwardVector.Rotation());
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
				UpdateSplinePosition();
			}

			MovementComponent.ApplyMove(MoveData);

			if (Player.Mesh.CanRequestLocomotion())
				Player.RequestLocomotion(n"SlideDash", this);

			// Accelerate relative location and convert to world
			AcceleratedRelativeMeshLocation = Math::VInterpTo(AcceleratedRelativeMeshLocation, GetRelativeMeshOffset(), DeltaTime, 5);
			FVector WorldMeshLocation = Player.ActorTransform.TransformPosition(AcceleratedRelativeMeshLocation);

			// Accelerate rotation
			AcceleratedMeshRotation = Math::QInterpTo(AcceleratedMeshRotation, SplinePosition.WorldRotation, DeltaTime, 10);

			// Create transform and go!
			FTransform MeshTransform(AcceleratedMeshRotation, WorldMeshLocation);
			Player.MeshOffsetComponent.SnapToTransform(this, MeshTransform);
		}

		TickForceFeedback();
	}

	void UpdateSplinePosition()
	{
		float DistanceAlongSpline = PigSiloComponent.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		SplinePosition = FSplinePosition(PigSiloComponent.CurrentSpline, DistanceAlongSpline, true);
	}

	void TickForceFeedback()
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * 25.0) * 0.1;
		FF.RightMotor = Math::Sin(-ActiveDuration * 25.0) * 0.1;
		Player.SetFrameForceFeedback(FF);
	}

	FVector GetRelativeMeshOffset() const
	{
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(SplinePosition.CurrentSpline.Owner);

		FHitResult HitResult = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.MovementWorldUp * 100);
		if (HitResult.bBlockingHit)
			return HitResult.Location - Player.ActorLocation;

		return FVector::ZeroVector;
	}
}