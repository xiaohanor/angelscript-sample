struct FGravityBikeWhipPullDeactivateParams
{
	bool bFinished = false;
	bool bReleasedInput = false;
}

class UGravityBikeWhipPullCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 110;

	UGravityBikeWhipComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Pull)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipPullDeactivateParams& Params) const
	{
		if(ActiveDuration > WhipComp.FeatureData.GetPullDuration())
		{
			Params.bFinished = true;
			Params.bReleasedInput = WhipComp.bReleasedInput;
			return true;
		}

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Pull)
		{
			Params.bFinished = false;
			Params.bReleasedInput = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.SetWhipState(EGravityBikeWhipState::Pull);

		FGravityBikeWhipGrabEventData EventData;
		EventData.GrabTargets = WhipComp.GrabbedTargets;
		UGravityBikeWhipEventHandler::Trigger_OnStartPull(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipPullDeactivateParams Params)
	{
		if(Params.bFinished)
		{
			if(Params.bReleasedInput)
			{
				WhipComp.SetWhipState(EGravityBikeWhipState::ThrowRebound);
			}
			else
			{
				WhipComp.SetWhipState(EGravityBikeWhipState::Lasso);
			}
		}
		else
		{
			WhipComp.DropAll();
			WhipComp.Reset();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			bool bReleasedInput = !IsActioning(GravityBikeWhip::GrabInput);
			
#if EDITOR
			if(GravityBikeWhip::AutoThrow.IsEnabled())
				bReleasedInput = true;

			if(GravityBikeWhip::HoldInput.IsEnabled())
			{
				bReleasedInput = false;
				WhipComp.bReleasedInput = false;
			}
#endif

			if(bReleasedInput)
				WhipComp.bReleasedInput = true;

			WhipComp.PollMultiGrab();
		}

		for(int i = 0; i < WhipComp.GetGrabbedCount(); i++)
		{
			UGravityBikeWhipGrabTargetComponent GrabbedTarget = WhipComp.GrabbedTargets[i];
			GrabbedTarget.GrabMoveData.Tick(i, ActiveDuration, DeltaTime, EGravityBikeWhipState::Pull);
		}

		if(Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GravityBikeWhip", this);
	}
};