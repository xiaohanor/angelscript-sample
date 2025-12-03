class USandSharkThumperDistractCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Attack);
	default TickGroup = EHazeTickGroup::Movement;

	default TickGroupOrder = SandShark::TickGroupOrder::ThumperDistract;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;
	USandSharkAnimationComponent AnimationComp;
	USandSharkSettings SharkSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);

		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SandShark.IsAffectedByThumpers())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (SandShark.bIsChasing)
		{
			if (SandShark.GetDistanceTo(SandShark.GetTargetPlayer()) < SandShark::PreferThumperDistance)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SandShark.IsAffectedByThumpers())
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SandShark.BlockCapabilities(SandSharkBlockedWhileIn::Distract, this);
		SandShark.BlockCapabilities(SandSharkBlockedWhileIn::ThumperDistract, this);
		SandShark.bIsDistractedByGroundPounder = true;
		USandSharkEventHandler::Trigger_OnThumperDistractionStarted(SandShark);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::Distract, this);
		SandShark.UnblockCapabilities(SandSharkBlockedWhileIn::ThumperDistract, this);

		SandShark.bIsDistractedByGroundPounder = false;
		MoveComp.RemoveCurrentSplineByInstigator(this);
		USandSharkEventHandler::Trigger_OnThumperDistractionStopped(SandShark);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FSandSharkThumperDistractionParams DistractionParams;
			if (SandShark.GetQueuedDistractionParams(DistractionParams))
			{
				MoveComp.ApplyCurrentSplineInstigator(DistractionParams.Spline, this, EInstigatePriority::High);
			}

			if (MoveComp.AccDive.Value < -75 || MoveComp.AccDive.Value > -75)
			{
				MoveComp.AccDive.AccelerateTo(-75, 0.5, DeltaTime);
			}

			FSplinePosition NewSplinePosition = SandShark.GetCurrentSpline().Spline.GetClosestSplinePositionToWorldLocation(SandShark.ActorLocation);
			NewSplinePosition.MatchFacingTo(SandShark.ActorQuat);
			NewSplinePosition.Move(100);

			FVector TargetLocation = NewSplinePosition.WorldLocation;
			MoveComp.UpdateMoveSplinePosition(NewSplinePosition);

			auto MoveData = SharkSettings.ThumperMovement;
			// Move fast when far from spline, move slower when close
			if (NewSplinePosition.WorldLocation.Dist2D(SandShark.ActorLocation) < 200)
			{
				MoveData.MovementSpeed = 800;
			}
			else
			{
				MoveData.MaxTurnAngle = 60;
				MoveData.TurnSpeed = 360;
				MoveData.MovementSpeedTurning = 100;
			}

			MoveComp.MoveNavigateToLocation(
				MoveData,
				TargetLocation,
				DeltaTime,
				MoveData.MovementSpeed,
				this);
		}
		else
		{
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}
	}
};