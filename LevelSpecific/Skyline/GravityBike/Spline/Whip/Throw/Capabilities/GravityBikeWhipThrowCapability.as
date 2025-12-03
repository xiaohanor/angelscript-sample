struct FGravityBikeWhipThrowDeactivateParams
{
	bool bFinished = false;
	UGravityBikeWhipThrowTargetComponent ThrowTarget = nullptr;
};

class UGravityBikeWhipThrowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 140;

	UGravityBikeWhipComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Throw)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipThrowDeactivateParams& Params) const
	{
		if(ActiveDuration > WhipComp.FeatureData.GetThrowDuration())
		{
			Params.bFinished = true;
			Params.ThrowTarget = WhipComp.GetThrowTarget();
			return true;
		}

		if(!WhipComp.HasGrabbedAnything())
			return true;

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Throw)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.SetWhipState(EGravityBikeWhipState::Throw);

		FGravityBikeWhipThrowEventData EventData = WhipComp.GetThrowEventData(WhipComp.GrabbedTargets);
		UGravityBikeWhipEventHandler::Trigger_OnStartThrow(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipThrowDeactivateParams Params)
	{
		if(Params.bFinished)
		{
			WhipComp.ThrowAll(Params.ThrowTarget);
		}
		else
		{
			WhipComp.DropAll();
		}

		WhipComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(int i = 0; i < WhipComp.GetGrabbedCount(); i++)
		{
			UGravityBikeWhipGrabTargetComponent GrabbedTarget = WhipComp.GrabbedTargets[i];
			GrabbedTarget.GrabMoveData.Tick(i, ActiveDuration, DeltaTime, EGravityBikeWhipState::Throw);
		}

		if(HasControl())
		{
			if(GravityBikeWhip::bIntervalBetweenThrows && WhipComp.IsMultiGrab())
			{
				const float TimeLeftToThrow = WhipComp.FeatureData.GetThrowDuration() - ActiveDuration;
				if(TimeLeftToThrow < (WhipComp.GetGrabbedCount() - 1) * GravityBikeWhip::IntervalBetweenThrows && WhipComp.IsMultiGrab())
				{
					CrumbThrow(WhipComp.GrabbedTargets.Last(), WhipComp.GetThrowTarget());
				}
			}
		}

		if(Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GravityBikeWhip", this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrow(UGravityBikeWhipGrabTargetComponent InGrabTarget, UGravityBikeWhipThrowTargetComponent InThrowTarget)
	{
		WhipComp.Throw(InGrabTarget, InThrowTarget);
	}
};