struct FSkylineBossPendingDownActivateParams
{
	ASkylineBossSplineHub AddNewHubToCurrentPath;
};

class USkylineBossPendingDownCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossPendingDown);

	// Before Combat
	default TickGroupOrder = 109;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossPendingDownActivateParams& Params) const
	{
		// Don't activate mid-step, as this will cause lerping issues
		// if (Boss.MovementData.bIsStepping)
		// 	return false;

		bool bShouldActivate = false;
		if(Boss.IsStateActive(ESkylineBossState::PendingDown))
			bShouldActivate = true;
		else if(Boss.IsStateActive(ESkylineBossState::Combat))
		{
			if(Boss.AreAllLegsDestroyed())
				bShouldActivate = true;
		}

		if(!bShouldActivate)
			return false;

		if(Boss.MovementQueue[0].ToHub.ActorLocation.DistXY(Boss.ActorLocation) < SkylineBoss::Fall::HorizontalDistanceThreshold)
		{
			//Too close, move to next hub
			if(Boss.GetPhase() == ESkylineBossPhase::First)
			{
				for(auto Hub : Boss.MovementQueue.Last().ToHub.ConnectedHubs)
				{
					if(Hub.bIsCenterHub || Hub == Boss.MovementQueue.Last().FromHub)
						continue;

					Params.AddNewHubToCurrentPath = Hub;
					break;
				}
			}
			else
			{
				Params.AddNewHubToCurrentPath = SkylineBoss::GetBestHubForFall(Boss.MovementQueue.Last().ToHub, Boss.MovementQueue.Last().FromHub);
			}
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.IsStateActive(ESkylineBossState::PendingDown))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossPendingDownActivateParams Params)
	{
		Boss.SetState(ESkylineBossState::PendingDown);

		if (Boss.PendingDownSettings != nullptr)
			Boss.ApplySettings(Boss.PendingDownSettings, this);

		if(HasControl())
		{
			if(Params.AddNewHubToCurrentPath != nullptr)
				Boss.AddNewHubToCurrentPath(Params.AddNewHubToCurrentPath);
		}

		USkylineBossEventHandler::Trigger_PendingDown(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();

		Boss.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			// Movement
			//.Add(USkylineBossPendingDownActivateFallCameraCapability())
			.Add(USkylineBossPendingDownBodyMovementCapability())
			.Add(USkylineBossPendingDownFootPlacementCapability())
			.Add(USkylineBossFeetSyncCapability())
			.Add(USkylineBossLookAtCapability())
			.Add(USkylineBossFootGroundedCapability())
		;
	}
}