struct FGravityBikeWhipThrowReboundDeactivateParams
{
	bool bFinished = false;
	UGravityBikeWhipThrowTargetComponent ThrowTarget;
};

class UGravityBikeWhipThrowReboundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 130;

	UGravityBikeWhipComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.GetWhipState() != EGravityBikeWhipState::ThrowRebound)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipThrowReboundDeactivateParams& Params) const
	{
		if(ActiveDuration > WhipComp.FeatureData.GetReboundDuration())
		{
			Params.bFinished = true;
			Params.ThrowTarget = WhipComp.GetThrowTarget();
			return true;
		}

		if(!WhipComp.HasGrabbedAnything())
			return true;

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::ThrowRebound)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.SetWhipState(EGravityBikeWhipState::ThrowRebound);

		FGravityBikeWhipThrowEventData EventData = WhipComp.GetThrowEventData(WhipComp.GrabbedTargets);
		UGravityBikeWhipEventHandler::Trigger_OnStartThrowRebound(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipThrowReboundDeactivateParams Params)
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
			GrabbedTarget.GrabMoveData.Tick(i, ActiveDuration, DeltaTime, EGravityBikeWhipState::ThrowRebound);
		}

		if(HasControl())
		{
			if(GravityBikeWhip::bIntervalBetweenThrows && WhipComp.IsMultiGrab())
			{
				const float TimeLeftToThrow = WhipComp.FeatureData.GetReboundDuration() - ActiveDuration;
				while(TimeLeftToThrow < (WhipComp.GetGrabbedCount() - 1) * GravityBikeWhip::IntervalBetweenThrows && WhipComp.IsMultiGrab())
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