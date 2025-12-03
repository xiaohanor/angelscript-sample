struct FIslandDroidZiplinePlayerEnterHangActivatedParams
{
	AIslandDroidZipline DroidZipline;
}

struct FIslandDroidZiplinePlayerEnterHangDeactivatedParams
{
	bool bAttached = false;
	FTransform ExpectedTransform;
}

class UIslandDroidZiplinePlayerNetworkHandshakeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"DroidZipline");

	default BlockExclusionTags.Add(n"DroidZipline");

	default TickGroup = EHazeTickGroup::Input;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTargetablesComponent TargetablesComponent;
	UIslandDroidZiplinePlayerComponent DroidZiplineComp;
	UIslandDroidZiplinePlayerSettings Settings;

	AIslandDroidZipline PendingZipline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		DroidZiplineComp = UIslandDroidZiplinePlayerComponent::Get(Player);
		Settings = UIslandDroidZiplinePlayerSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandDroidZiplinePlayerEnterHangActivatedParams& Params) const
	{
		if(!HasControl())
			return false;

		if(DroidZiplineComp.CurrentTargetable != nullptr)
			return false;

		if(!WasActionStarted(ActionNames::ContextualMovement))
			return false;

		auto Targetable = TargetablesComponent.GetPrimaryTarget(UIslandDroidZiplineAttachTargetable);

		if(Targetable == nullptr)
			return false;

		auto DroidZipline = Cast<AIslandDroidZipline>(Targetable.Owner);

		if(DroidZipline == nullptr)
			return false;

		if(DroidZipline.bOccupied)
			return false;

		FTransform ExpectedDroidTransform;
		if(!GetExpectedDroidTransform(DroidZipline, ExpectedDroidTransform))
			return false;

		Params.DroidZipline = DroidZipline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FIslandDroidZiplinePlayerEnterHangDeactivatedParams& Params) const
	{
		if (!IsValid(PendingZipline))
		{
			Params.bAttached = false;
			return true;
		}

		// Finish attaching when we've acquired the lock and the zipline isn't occupied
		if (PendingZipline.NetworkLock.IsAcquired(Player))
		{
			Params.bAttached = !PendingZipline.bOccupied;
			if (!GetExpectedDroidTransform(PendingZipline, Params.ExpectedTransform))
				Params.bAttached = false;
			if (Player.IsPlayerDead())
				Params.bAttached = false;
			return true;
		}

		// Cancel out if the other player holds the lock
		if (PendingZipline.NetworkLock.IsAcquired(Player.OtherPlayer))
		{
			Params.bAttached = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandDroidZiplinePlayerEnterHangActivatedParams Params)
	{
		PendingZipline = Params.DroidZipline;
		PendingZipline.NetworkLock.Acquire(Player, this);

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FIslandDroidZiplinePlayerEnterHangDeactivatedParams Params)
	{
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		if (IsValid(PendingZipline))
			PendingZipline.NetworkLock.Release(Player, this);

		if (Params.bAttached)
		{
			DroidZiplineComp.ExpectedDroidTransform = Params.ExpectedTransform;
			PendingZipline.LockToPlayer(DroidZiplineComp);
		}
	}

	float GetTotalEnterDuration() const property
	{
		return Settings.JumpToDroidDuration + Settings.ThrowGrappleDuration;
	}

	bool GetExpectedDroidTransform(AIslandDroidZipline DroidZipline, FTransform&out ExpectedDroidTransform) const
	{
		switch(DroidZipline.CurrentDroidState)
		{
			case EIslandDroidZiplineState::Patrolling:
			{
				UIslandDroidZiplineSettings DroidSettings = UIslandDroidZiplineSettings::GetSettings(DroidZipline);
				float CurrentDroidSplineDistance = DroidZipline.PatrolSpline.Spline.GetClosestSplineDistanceToWorldLocation(DroidZipline.ActorLocation);

				if(CurrentDroidSplineDistance + (DroidSettings.PatrolSpeed * TotalEnterDuration) >= DroidZipline.PatrolSpline.Spline.SplineLength)
					return false;

				float TargetDroidSplineDistance = CurrentDroidSplineDistance + DroidSettings.PatrolSpeed * TotalEnterDuration;
				ExpectedDroidTransform = DroidZipline.PatrolSpline.Spline.GetWorldTransformAtSplineDistance(TargetDroidSplineDistance);
				break;
			}
			case EIslandDroidZiplineState::Static:
			{
				ExpectedDroidTransform = DroidZipline.ActorTransform;
				break;
			}
			case EIslandDroidZiplineState::Ziplining:
			{
				// If it's ziplining, the expected transform shouldn't be used because the other player is already occupying it,
				// but this function can still be called, so return a sane value, but count on it not actually being used
				ExpectedDroidTransform = DroidZipline.ActorTransform;
				break;
			}
		}
		
		return true;
	}
}