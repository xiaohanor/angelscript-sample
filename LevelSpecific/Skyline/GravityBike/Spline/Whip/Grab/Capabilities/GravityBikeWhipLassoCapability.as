struct FGravityBikeWhipLassoDeactivateParams
{
	bool bReleased = false;
}

class UGravityBikeWhipLassoCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 120;

	UGravityBikeWhipComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Lasso)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipLassoDeactivateParams& Params) const
	{
		bool bReleasedInput = !IsActioning(GravityBikeWhip::GrabInput);

#if EDITOR
		if(GravityBikeWhip::AutoThrow.IsEnabled())
			bReleasedInput = true;

		if(GravityBikeWhip::HoldInput.IsEnabled())
			bReleasedInput = false;
#endif

		if(bReleasedInput)
		{
			Params.bReleased = true;
			return true;
		}

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::Lasso)
		{
			Params.bReleased = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.SetWhipState(EGravityBikeWhipState::Lasso);

		FGravityBikeWhipGrabEventData EventData;
		EventData.GrabTargets = WhipComp.GrabbedTargets;
		UGravityBikeWhipEventHandler::Trigger_OnStartLasso(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipLassoDeactivateParams Params)
	{
		if(Params.bReleased)
		{
			WhipComp.SetWhipState(EGravityBikeWhipState::Throw);
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
		for(int i = 0; i < WhipComp.GetGrabbedCount(); i++)
		{
			UGravityBikeWhipGrabTargetComponent GrabbedTarget = WhipComp.GrabbedTargets[i];
			GrabbedTarget.GrabMoveData.Tick(i, ActiveDuration, DeltaTime, EGravityBikeWhipState::Lasso);
		}

		if(Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GravityBikeWhip", this);
	}
};