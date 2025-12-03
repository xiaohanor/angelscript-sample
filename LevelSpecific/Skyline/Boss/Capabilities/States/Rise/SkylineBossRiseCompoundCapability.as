struct FSkylineBossRiseCompoundActivateParams
{
	ESkylineBossPhase Phase;
	ASkylineBossSplineHub CurrentHub;
};

struct FSkylineBossRiseCompoundDeactivateParams
{
	bool bFinished = false;
};

class USkylineBossRiseCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossRise);

	// After Down
	default TickGroupOrder = 101;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossRiseCompoundActivateParams& Params) const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Rise))
			return false;

		Params.Phase = Boss.GetPhase();
		Params.CurrentHub = Boss.CurrentHub;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBossRiseCompoundDeactivateParams& Params) const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Rise))
			return true;

		// if (ActiveDuration > SkylineBoss::Rise::GetTotalDuration())
		// {
		// 	Params.bFinished = true;
		// 	return true;
		// }

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossRiseCompoundActivateParams Params)
	{
		Boss.CurrentHub = Params.CurrentHub;

		Boss.SetState(ESkylineBossState::Rise);
		Boss.RestoreLegs();
		Boss.OnBeginRise.Broadcast();
		USkylineBossEventHandler::Trigger_TripodRise(Boss);

		Boss.ResetFootTargets();

		if (Params.Phase == ESkylineBossPhase::First)
			Boss.SetPhase(ESkylineBossPhase::Second);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBossRiseCompoundDeactivateParams Params)
	{
		ResetCompoundNodes();
		
		Boss.SyncedHeadPivotRotationComp.TransitionSync(this);

		if(Params.bFinished)
		{
			Boss.OnRise.Broadcast();
			Boss.SetState(ESkylineBossState::Combat);

//			Boss.RestoreLegs();
		}

	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(USkylineBossFeetFollowAnimationCapability())
			//.Add(USkylineBossRiseMovementChildCapability())
		;
	}
};