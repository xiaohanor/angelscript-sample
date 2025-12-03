struct FGravityBikeWhipStartGrabActivateParams
{
	TArray<UGravityBikeWhipGrabTargetComponent> Targets;
}

struct FGravityBikeWhipStartGrabDeactivateParams
{
	bool bFinished = false;
	bool bReleasedInput = false;
}

class UGravityBikeWhipStartGrabCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UGravityBikeWhipComponent WhipComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeWhipStartGrabActivateParams& Params) const
	{
		if(WhipComp.GetWhipState() != EGravityBikeWhipState::None)
			return false;

		bool bInput = WasActionStarted(GravityBikeWhip::GrabInput);

#if EDITOR
		if(GravityBikeWhip::AutoThrow.IsEnabled())
			bInput = true;

		if(GravityBikeWhip::HoldInput.IsEnabled())
			bInput = true;
#endif

		if(!bInput)
			return false;

		const TArray<UGravityBikeWhipGrabTargetComponent> ValidGrabTargets = WhipComp.GetAllValidGrabTargets();

		if (ValidGrabTargets.Num() == 0)
			return false;

		Params.Targets = ValidGrabTargets;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeWhipStartGrabDeactivateParams& Params) const
	{
		if(ActiveDuration > WhipComp.FeatureData.GetStartPullDuration())
		{
			Params.bFinished = true;
			Params.bReleasedInput = WhipComp.bReleasedInput;
			return true;
		}

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::StartGrab)
		{
			Params.bFinished = false;
			Params.bReleasedInput = WhipComp.bReleasedInput;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeWhipStartGrabActivateParams Params)
	{
		check(Params.Targets.Num() != 0);

		WhipComp.Reset();

		WhipComp.SetWhipState(EGravityBikeWhipState::StartGrab);

		WhipComp.Grab(Params.Targets);

		FGravityBikeWhipGrabEventData EventData;
		EventData.GrabTargets = WhipComp.GrabbedTargets;
		UGravityBikeWhipEventHandler::Trigger_OnStartGrab(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeWhipStartGrabDeactivateParams Params)
	{
		if(Params.bFinished)
		{
			WhipComp.bReleasedInput = Params.bReleasedInput;
			WhipComp.SetWhipState(EGravityBikeWhipState::Pull);
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
			if(!IsActioning(GravityBikeWhip::GrabInput))
				WhipComp.bReleasedInput = true;

			WhipComp.PollMultiGrab();
		}

		for(int i = 0; i < WhipComp.GetGrabbedCount(); i++)
		{
			UGravityBikeWhipGrabTargetComponent GrabbedTarget = WhipComp.GrabbedTargets[i];
			GrabbedTarget.GrabMoveData.Tick(i, ActiveDuration, DeltaTime, EGravityBikeWhipState::StartGrab);
		}

		if(Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"GravityBikeWhip", this);
	}
};