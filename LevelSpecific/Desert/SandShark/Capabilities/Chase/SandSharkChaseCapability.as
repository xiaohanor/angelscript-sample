struct FSandSharkChaseDeactivateParams
{
	ASandSharkSpline TargetSpline;
} class USandSharkChaseCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkChase);

	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = SandShark::TickGroupOrder::Chase;
	default TickGroupSubPlacement = 2;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;

	USandSharkChaseComponent ChaseComp;
	USandSharkAnimationComponent AnimationComp;
	USandSharkSettings SharkSettings;
	UPathfollowingSettings PathFollowSettings;
	UGroundPathfollowingSettings GroundPathFollowSettings;

	FVector LastValidLocation;

	float CurrentDistance = 0;

	FNavigationPath PreviousPath;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		ChaseComp = USandSharkChaseComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
		PathFollowSettings = UPathfollowingSettings::GetSettings(Owner);
		GroundPathFollowSettings = UGroundPathfollowingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!ChaseComp.bIsChasing)
			return false;

		if (!SandShark.HasTargetPlayer())
			return false;

		if (ChaseComp.State == ESandSharkChaseState::Diving)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSandSharkChaseDeactivateParams& Params) const
	{
		bool bShouldExit = false;

		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return true;

		if (MoveComp.HasMovedThisFrame())
			bShouldExit = true;

		if (!ChaseComp.bIsChasing)
			bShouldExit = true;

		if (!SandShark.HasTargetPlayer())
			bShouldExit = true;

		if (bShouldExit)
		{
			Params.TargetSpline = GetSplineTarget();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ChaseComp.DistanceToTarget = MAX_flt;
		CurrentDistance = 0;
		AnimationComp.AddAnimChaseInstigator(this);
		ChaseComp.State = ESandSharkChaseState::Ground;
		// SandShark.ApplySettings(SandShark::Settings::ChaseSettings, this);
		LastValidLocation = SandShark.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSandSharkChaseDeactivateParams Params)
	{
		AnimationComp.RemoveAnimChaseInstigator(this);
		SandShark.bIsChasing = false;
		SandShark.ClearSettingsByInstigator(this);
		AnimationComp.Data.BoneRelaxSpeedScale = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto TraceSettings = SandShark.GetTraceSettings(50);
		const auto Overlaps = TraceSettings.QueryOverlaps(
			Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, SandShark.LandscapeLevel));

		if (!Overlaps.HasBlockHit())
		{
			float TargetAscensionTime = 1;
			MoveComp.AccDive.AccelerateTo(55, TargetAscensionTime, DeltaTime);
			// SandShark.bIsAvoidingObstacles = false;
		}
		else
		{
			MoveComp.AccDive.AccelerateTo(-550, 1, DeltaTime);
			// SandShark.bIsAvoidingObstacles = true;
		}

		if (HasControl())
		{
			if (SandShark.MoveToComp.Path.Points != PreviousPath.Points)
			{
				CurrentDistance = 0;
			}

			PreviousPath = SandShark.MoveToComp.Path;

			if (SandShark.MoveToComp.Path.IsValid())
			{
				auto Points = SandShark.MoveToComp.Path.Points;
				if (Points.Num() >= 2)
				{
					FHazeRuntimeSpline RuntimeSpline;
					RuntimeSpline.SetPoints(Points);
					RuntimeSpline.CustomExitTangentPoint = RuntimeSpline.Points.Last() + SandShark.ActorRightVector * 500;
					//RuntimeSpline.DrawDebugSpline();
					RuntimeSpline.Tension = 0;
					if (Math::IsNearlyZero(CurrentDistance))
						CurrentDistance = RuntimeSpline.GetClosestSplineDistanceToLocation(SandShark.ActorLocation);

					FVector CurrentLocation = RuntimeSpline.GetLocationAtDistance(CurrentDistance);
					if (SandShark.ActorForwardVector.DotProduct(CurrentLocation - SandShark.ActorLocation) > 0.5)
						CurrentDistance += MoveComp.AccMovementSpeed.Value * DeltaTime;
					// RuntimeSpline.DrawDebugSpline();
					CurrentDistance = Math::Clamp(CurrentDistance, 0, RuntimeSpline.Length);
					FVector Location = RuntimeSpline.GetLocationAtDistance(CurrentDistance);
					if (Location.IsNearlyZero())
						Location = SandShark.ActorLocation;

					MoveComp.MoveNavigateToLocation(SharkSettings.ChaseMovement, Location, DeltaTime, SharkSettings.ChaseMovement.MovementSpeed, this);

					ChaseComp.DistanceToTarget = SandShark.HeadLocation.Dist2D(SandShark.GetTargetPlayer().ActorLocation);
				}
			}
			else
			{
				MoveComp.MoveNavigateToLocation(SharkSettings.ChaseMovement, SandShark.GetTargetPlayer().ActorLocation, DeltaTime, SharkSettings.ChaseMovement.MovementSpeed, this);
			}

			LastValidLocation = SandShark.ActorLocation;
		}
		else
		{
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}

		if (SandShark.SyncedMeshLocationComp.Value.Z < -250)
		{
			AnimationComp.Data.BoneRelaxSpeedScale = 4.0;
		}
		else
		{
			AnimationComp.Data.BoneRelaxSpeedScale = 0.0;
		}
	}

	ASandSharkSpline GetSplineTarget() const
	{
		auto Player = SandShark.GetTargetPlayer();
		auto PlayerLastSafePoint = USandSharkPlayerComponent::Get(Player).LastSafePoint;
		ASandSharkSpline SplineTarget;
		if (PlayerLastSafePoint != nullptr)
			SplineTarget = PlayerLastSafePoint.Spline;
		else
			SplineTarget = SandShark.GetCurrentSpline();

		return SplineTarget;
	}
};