struct FGrappleFishSplineMovementActivationParams
{
	float RightOffset = 0;
}

class UDesertGrappleFishFollowSplineMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;
	default TickGroupSubPlacement = 0;

	ADesertGrappleFish GrappleFish;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UDesertGrappleFishComponent GrappleFishComp;
	float CurrentRightOffset;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
		GrappleFishComp = UDesertGrappleFishComponent::Get(GrappleFish);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USimpleMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrappleFishSplineMovementActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return false;

		if (!GrappleFish.HasAutoPilotOverride())
		{
			if (GrappleFish.IsRiderAlive())
				return false;
		}
		else
		{
#if EDITOR
			if (GrappleFish.HasAliveAutoPilotDebug())
				return false;
#endif
		}

		FVector ToSpline = (GrappleFish.ActorLocation - GrappleFish.AutoPilotSplinePosition.WorldLocation);
		if (ToSpline.Size() > 5000)
			return false;

		float RightOffset = GrappleFish.AutoPilotSplinePosition.WorldRightVector.DotProduct(ToSpline);
		if (Math::Abs(RightOffset) > 250)
			return false;

		Params.RightOffset = RightOffset;
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
	void OnActivated(FGrappleFishSplineMovementActivationParams Params)
	{
		CurrentRightOffset = Params.RightOffset;
		AccRotation.SnapTo(GrappleFish.ActorRotation);
		UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(GrappleFish);
		GrappleFish.bIsFollowingSpline = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (GrappleFish.bTriggerEndJump)
		{
			GrappleFish.SharkMesh.RelativeRotation = FRotator::ZeroRotator;
			GrappleFish.SharkRoot.RelativeRotation = FRotator::ZeroRotator;
		}
		GrappleFish.bIsFollowingSpline = false;
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

			GrappleFish.AccTurnSpeed.AccelerateTo(0, 0.25, DeltaTime);

			if (GrappleFish.bIsDiving)
				GrappleFish.AccMoveSpeed.AccelerateTo(GrappleFish.GetMovementSpeed(), GrappleFishMovement::DiveMovementAccelerationDuration, DeltaTime);
			else
				GrappleFish.AccMoveSpeed.AccelerateTo(GrappleFish.GetMovementSpeed(), GrappleFishMovement::MovementAccelerationDuration, DeltaTime);

			GrappleFish.AutoPilotSplinePosition.Move(GrappleFish.AccMoveSpeed.Value * DeltaTime);

			CurrentRightOffset = Math::FInterpConstantTo(CurrentRightOffset, 0, DeltaTime, 80);

			FVector TargetLocation = GrappleFish.AutoPilotSplinePosition.WorldLocation + GrappleFish.AutoPilotSplinePosition.WorldRightVector * CurrentRightOffset;
			TargetLocation = Desert::GetLandscapeLocationByLevel(TargetLocation, ESandSharkLandscapeLevel::Secondary);
			FVector MoveDelta = TargetLocation - GrappleFish.ActorLocation;
			Movement.AddDelta(MoveDelta);
			AccRotation.AccelerateTo(FRotator::MakeFromXZ(MoveDelta.GetSafeNormal(), FVector::UpVector), 0.5, DeltaTime);
			Movement.SetRotation(AccRotation.Value);
			FVector Normal = Desert::GetLandscapeNormal(GrappleFish.ActorTransform, GrappleFish.LandscapeLevel);
			GrappleFish.AccLandscapeNormal.AccelerateTo(Normal, GrappleFishMovement::LandscapeHeightAccelerationDuration, DeltaTime);
			GrappleFish.AccMeshForward.AccelerateTo(MoveDelta.GetSafeNormal(), 0.5, DeltaTime);

			float ClampedDeltaTime = DeltaTime;
			if (ClampedDeltaTime == 0)
				ClampedDeltaTime = 0.016;
			GrappleFish.Velocity = MoveDelta / ClampedDeltaTime;

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
};