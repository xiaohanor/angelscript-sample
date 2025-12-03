class UDesertGrappleFishAutoPilotCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;
	default TickGroupSubPlacement = 1;
	ADesertGrappleFish GrappleFish;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;
	bool bRiderIsDead;

	float DesiredRightOffset = 0;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccLandscapeHeight;
	FHazeAcceleratedFloat AccHorizontalSpeed;

	FSplinePosition BoundarySplinePosition;

	UDesertGrappleFishComponent GrappleFishComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
		GrappleFishComp = UDesertGrappleFishComponent::Get(GrappleFish);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USimpleMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return false;

#if EDITOR
		if (GrappleFish.bIsDebuggingDive)
			return false;

#endif

		if (!GrappleFish.HasAutoPilotOverride())
		{
			if (GrappleFish.HasRider() && GrappleFish.IsRiderAlive())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return true;

		if (!GrappleFish.HasAutoPilotOverride())
		{
			if (GrappleFish.HasRider() && GrappleFish.IsRiderAlive() && Time::GetGameTimeSince(GrappleFish.TimeWhenPlayerRespawned) >= GrappleFishPlayer::ExtendedRespawnAutoPilotDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bRiderIsDead = false;
		GrappleFish.AutoPilotSplinePosition = GrappleFish.AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
		BoundarySplinePosition = GrappleFish.BoundarySpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.AutoPilotSplinePosition.WorldLocation);
		DesiredRightOffset = GetOffsetFromBoundary();
		GrappleFish.AccTurnSpeed.SnapTo(0);
		AccRotation.SnapTo(GrappleFish.ActorRotation);
		AccLandscapeHeight.SnapTo(Desert::GetLandscapeHeightByLevel(GrappleFish.ActorLocation, GrappleFish.LandscapeLevel));
		if (!GrappleFish.bIsDiving)
			UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(GrappleFish);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (GrappleFish.bTriggerEndJump)
		{
			GrappleFish.SharkMesh.RelativeRotation = FRotator::ZeroRotator;
			GrappleFish.SharkRoot.RelativeRotation = FRotator::ZeroRotator;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
		{
			return;
		}

		if (HasControl())
		{
			if (GrappleFishComp.HasDiveBreachedSand())
			{
				GrappleFishComp.ConsumeDiveBreach();
				FGrappleFishSandSurfaceBreachedParams Params;
				FVector NeckLocation = GrappleFish.SharkMesh.GetSocketLocation(n"Neck");
				Params.SandBreachLocation = Desert::GetLandscapeLocationByLevel(NeckLocation, GrappleFish.LandscapeLevel);
				UDesertGrappleFishEventHandler::Trigger_OnDiveSandSurfaceBreached(GrappleFish, Params);
			}
			if (GrappleFishComp.HasResurfaceBreachedSand())
			{
				GrappleFishComp.ConsumeResurfaceBreach();
				UDesertGrappleFishEventHandler::Trigger_OnResurface(GrappleFish);
			}
			GrappleFish.AutoPilotSplinePosition = GrappleFish.AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
			if (GrappleFish.bIsDiving)
				GrappleFish.AccMoveSpeed.AccelerateTo(GrappleFish.GetMovementSpeed(), GrappleFishMovement::DiveMovementAccelerationDuration, DeltaTime);
			else
				GrappleFish.AccMoveSpeed.AccelerateTo(GrappleFish.GetMovementSpeed(), GrappleFishMovement::MovementAccelerationDuration, DeltaTime);

			if (GrappleFish.ControllingPlayer.IsPlayerDead() || GrappleFish.ControllingPlayer.IsPlayerRespawning())
				bRiderIsDead = true;
#if EDITOR
			if (GrappleFish.ControllingPlayer.IsMio() && !GrappleFishMovement::MioAutoPilotDisabled.IsEnabled())
			{
				if (GrappleFishMovement::MioAutoPilotDead.IsEnabled())
					bRiderIsDead = true;
				else
					bRiderIsDead = false;
			}
			else if (GrappleFish.ControllingPlayer.IsZoe() && !GrappleFishMovement::ZoeAutoPilotDisabled.IsEnabled())
			{
				if (GrappleFishMovement::ZoeAutoPilotDead.IsEnabled())
					bRiderIsDead = true;
				else
					bRiderIsDead = false;
			}
#endif

			HandleAutoPilot(DeltaTime);

			GrappleFish.SyncedRootRotation.SetValue(FRotator::MakeFromXZ(GrappleFish.AccMeshForward.Value, GrappleFish.AccLandscapeNormal.Value));
			GrappleFish.SyncedMeshRotation.SetValue(Math::RInterpShortestPathTo(GrappleFish.SharkMesh.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 5));
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		if (!GrappleFish.bIsDiving)
		{
			GrappleFish.InstigatedMoveSpeed.Clear(this);
		}

		if (ActiveDuration > GrappleFishAnimations::DiveDuration - 0.2 && GrappleFish.AnimData.bIsDiving)
		{
			GrappleFish.Resurface();
		}
		else if (ActiveDuration > GrappleFishAnimations::DiveDuration - 0.4 && GrappleFish.AnimData.bIsDiving)
		{
			GrappleFish.InstigatedMoveSpeed.Apply(GrappleFishMovement::DivingIdealMoveSpeed, this, EInstigatePriority::High);
		}

		MoveComp.ApplyMove(Movement);

		GrappleFish.SharkMesh.RelativeRotation = GrappleFish.SyncedMeshRotation.GetValue();
		GrappleFish.SharkRoot.SetWorldRotation(GrappleFish.SyncedRootRotation.GetValue());
	}

	float GetOffsetFromBoundary()
	{
		FVector ToGrappleFish = GrappleFish.ActorLocation - BoundarySplinePosition.WorldLocation;
		return ToGrappleFish.DotProduct(BoundarySplinePosition.WorldRightVector);
	}

	FVector GetClampedOffsetLocation()
	{
		auto SplineActor = Cast<ASandSharkSpline>(BoundarySplinePosition.CurrentSpline.Owner);
		FVector DesiredLocation;
		if (!bRiderIsDead && !GrappleFish.bForceAutoPilot)
			DesiredLocation = BoundarySplinePosition.WorldLocation + BoundarySplinePosition.WorldRightVector * DesiredRightOffset;
		else
		{
			auto DesiredSplinePos = GrappleFish.AutoPilotSplinePosition;
			DesiredSplinePos.Move(600);
			DesiredLocation = DesiredSplinePos.WorldLocation;
		}

		FVector ToDesired = DesiredLocation - BoundarySplinePosition.WorldLocation;
		float RightOffset = ToDesired.DotProduct(BoundarySplinePosition.WorldRightVector);
		float ForwardOffset = ToDesired.DotProduct(BoundarySplinePosition.WorldForwardVector);
		float SplineBounds = SplineActor.GetGrappleFishBoundsAtSplinePosition(BoundarySplinePosition);
		float ClampedOffset = Math::Clamp(RightOffset, -SplineBounds, SplineBounds);
		FVector WorldLocation = BoundarySplinePosition.WorldLocation + BoundarySplinePosition.WorldRightVector * ClampedOffset + BoundarySplinePosition.WorldForwardVector * ForwardOffset;
		TEMPORAL_LOG(this).Sphere("TargetLocation", WorldLocation, 250, FLinearColor::LucBlue, 10);
		return WorldLocation;
	}

	float GetDesiredHorizontalOffset(FSplinePosition SplinePos)
	{
		auto SplineActor = Cast<ASandSharkSpline>(BoundarySplinePosition.CurrentSpline.Owner);
		float SplineBounds = SplineActor.GetGrappleFishBoundsAtSplinePosition(BoundarySplinePosition);
		return Math::Clamp(DesiredRightOffset, -SplineBounds, SplineBounds);
	}

	void HandleAutoPilot(float DeltaTime)
	{
		float MoveSpeed = GrappleFish.AccMoveSpeed.Value;

		BoundarySplinePosition = GrappleFish.BoundarySpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
		FVector OffsetLocation = GetClampedOffsetLocation();

		FVector ToOffset = (OffsetLocation - GrappleFish.ActorLocation);
		float OffsetDistance = ToOffset.Size2D();

		if (OffsetDistance < 600)
			AccHorizontalSpeed.AccelerateTo(OffsetDistance * 3, GrappleFishMovement::ForceAutoPilotHorizontalAccelerationDuration, DeltaTime);
		else
		{
			float AccDuration = GrappleFish.bForceAutoPilot ? GrappleFishMovement::ForceAutoPilotHorizontalAccelerationDuration : GrappleFishMovement::AutoPilotHorizontalAccelerationDuration;
			AccHorizontalSpeed.AccelerateTo(GrappleFishMovement::AutoPilotStrafeMovementSpeed, AccDuration, DeltaTime);
		}

		FVector ForwardDelta = GrappleFish.ActorForwardVector * MoveSpeed * DeltaTime;
		FVector HorizontalOffsetDelta = ToOffset.GetSafeNormal2D() * AccHorizontalSpeed.Value * DeltaTime;

		GrappleFish.AccTurnSpeed.AccelerateTo(0, 0.25, DeltaTime);

		FVector Normal = Desert::GetLandscapeNormal(GrappleFish.ActorTransform, GrappleFish.LandscapeLevel);
		GrappleFish.AccLandscapeNormal.AccelerateTo(Normal, GrappleFishMovement::LandscapeHeightAccelerationDuration, DeltaTime);

		FVector HorizontalMoveDelta = (ForwardDelta + HorizontalOffsetDelta);
		FVector NewLocation = GrappleFish.ActorLocation + HorizontalMoveDelta;
		float VerticalDelta = Desert::GetLandscapeHeightByLevel(NewLocation, GrappleFish.LandscapeLevel) - GrappleFish.ActorLocation.Z;
		FVector FinalMoveDelta = HorizontalMoveDelta + (FVector::UpVector * VerticalDelta);
		Movement.AddDelta(FinalMoveDelta);
		GrappleFish.Velocity = FinalMoveDelta / DeltaTime;

		float Dot = ToOffset.GetSafeNormal().VectorPlaneProject(FVector::UpVector).DotProduct(GrappleFish.ActorForwardVector.VectorPlaneProject(FVector::UpVector));
		if (OffsetDistance > 600 || Dot < 0.4)
			AccRotation.AccelerateTo(FRotator::MakeFromXZ(FinalMoveDelta.GetSafeNormal().VectorPlaneProject(FVector::UpVector), FVector::UpVector), 1, DeltaTime);
		else
			AccRotation.AccelerateTo(FRotator::MakeFromXZ(GrappleFish.AutoPilotSplinePosition.WorldForwardVector.VectorPlaneProject(FVector::UpVector), FVector::UpVector), 0.5, DeltaTime);
		Movement.SetRotation(AccRotation.Value);
		GrappleFish.AccMeshForward.AccelerateTo(FinalMoveDelta.GetSafeNormal(), 0.25, DeltaTime);

		TEMPORAL_LOG(this).Sphere("ActorLocation", GrappleFish.ActorLocation, 140, FLinearColor::LucBlue, 5);
		TEMPORAL_LOG(this).Sphere("NewLocation", NewLocation, 150, FLinearColor::Yellow, 5);
		TEMPORAL_LOG(this).DirectionalArrow("MoveDelta", GrappleFish.ActorLocation, HorizontalMoveDelta * 1000, 50, 20, FLinearColor::Purple);
		TEMPORAL_LOG(this).DirectionalArrow("LandscapeNormal", GrappleFish.ActorLocation, Normal * 1050, 50, 20, FLinearColor::LucBlue);
		TEMPORAL_LOG(this).DirectionalArrow("AccLandscapeNormal", GrappleFish.ActorLocation, GrappleFish.AccLandscapeNormal.Value * 2050, 50, 20, FLinearColor::Blue);
		TEMPORAL_LOG(this).Value("AccLandscapeHeight", AccLandscapeHeight.Value);
	}

	FVector GetClampedLocationWithinBoundary(FVector WorldLocation, FSplinePosition SplinePosition) const
	{
		FVector SplineToWantedLocation = WorldLocation - SplinePosition.WorldLocation;
		auto SplineActor = Cast<ASandSharkSpline>(SplinePosition.CurrentSpline.Owner);
		float DistanceToRight = SplinePosition.WorldRightVector.DotProduct(SplineToWantedLocation);

		float SplineBounds = SplineActor.GetGrappleFishBoundsAtSplinePosition(SplinePosition);
		DistanceToRight = Math::Clamp(DistanceToRight, -SplineBounds, SplineBounds);

		float DistanceUpwards = SplinePosition.WorldUpVector.DotProduct(SplineToWantedLocation);

		float DistanceForwards = SplinePosition.WorldForwardVector.DotProduct(SplineToWantedLocation);
		FVector ClampedLocation = SplinePosition.WorldLocation + SplinePosition.WorldForwardVector * DistanceForwards + SplinePosition.WorldRightVector * DistanceToRight + SplinePosition.WorldUpVector * DistanceUpwards;

		TEMPORAL_LOG(this)
			.DirectionalArrow("Distance To Right", SplinePosition.WorldLocation, SplinePosition.WorldRightVector * DistanceToRight, 50, 80, FLinearColor::Green)
			.DirectionalArrow("Distance Upwards", SplinePosition.WorldLocation, SplinePosition.WorldUpVector * DistanceUpwards, 50, 80, FLinearColor::Blue);
		return ClampedLocation;
	}
};