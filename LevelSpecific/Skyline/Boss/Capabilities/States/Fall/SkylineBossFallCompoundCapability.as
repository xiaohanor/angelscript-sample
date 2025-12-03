asset SkylineBossFallSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBossFallCompoundCapability);
};

struct FSkylineBossFallActivateParams
{
	ASkylineBossSplineHub FallDownHub;
	ESkylineBossPhase Phase;
	ESkylineBossFallDirection FallDirection;
};

class USkylineBossFallCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFall);

	// Before PendingDown
	default TickGroupOrder = 108;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossFallActivateParams& Params) const
	{
		bool bShouldActivate = false;
		if(Boss.IsStateActive(ESkylineBossState::Fall))
			bShouldActivate = true;

		if(Boss.IsStateActive(ESkylineBossState::PendingDown))
		{
			if(Boss.MovementQueue.Num() == 1)
			{
				if(Boss.MovementQueue[0].ToHub.ActorLocation.DistXY(Boss.ActorLocation) < SkylineBoss::Fall::HorizontalDistanceThreshold)
				{
					bShouldActivate = true;
				}
			}
		}

		if(!bShouldActivate)
			return false;

		Params.FallDownHub = Boss.GetNextHub();

		Params.Phase = Boss.GetPhase();

		if(Boss.PreviousHub == nullptr || Boss.CurrentHub.bIsCenterHub)
			Params.FallDirection = ESkylineBossFallDirection::FromCenter;
		else
			Params.FallDirection = ESkylineBossFallDirection::FromLeft;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Fall))
			return true;

		if (ActiveDuration >= SkylineBoss::Fall::Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossFallActivateParams Params)
	{
		Boss.SetState(ESkylineBossState::Fall);

		Boss.OnBeginFall.Broadcast(Params.FallDownHub);
		Boss.OnFall.Broadcast();
		
		Boss.AnimData.FallDirection = Params.FallDirection;

		USkylineBossEventHandler::Trigger_BeginFall(Boss);

		if (Params.Phase == ESkylineBossPhase::First)
			USkylineBossEventHandler::Trigger_TripodFirstFall(Boss);
		else
			USkylineBossEventHandler::Trigger_TripodSecondFall(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();

		Boss.SetState(ESkylineBossState::Down);

		Boss.TraversalToHubCompleted();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			if(Player.IsPlayerDead())
				continue;
			
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Boss.BodyCollisionSphere);
			Trace.UseBoxShape(100, 100, 200, Player.ActorQuat);

			auto OverlapResult = Trace.QueryOverlapComponent(Player.ActorLocation);
			
			if(OverlapResult.Actor != nullptr)
			{
				Player.KillPlayer(FPlayerDeathDamageParams(-FVector::UpVector, 15.0), Boss.DeathDamageComp.LargeObjectDeathEffect);
			}
		}	
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(USkylineBossFallMovementCapability())
			.Add(USkylineBossFeetFollowAnimationCapability())
		;
	}
};