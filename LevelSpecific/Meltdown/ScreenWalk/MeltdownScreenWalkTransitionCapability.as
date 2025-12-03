class UMeltdownScreenWalkTransitionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMeltdownScreenWalkTransitionComponent TransitionComp;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FMeltdownScreenWalkTransitionData ParamData;

	bool bHasFinishedTransition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TransitionComp = UMeltdownScreenWalkTransitionComponent::Get(Player);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownScreenWalkTransitionData& OutParams) const
	{
		if(!TransitionComp.bTransition)
			return false; 

		if(!Player.HasActorBegunPlay())
			return false;

		OutParams = TransitionComp.Data;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 0.2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownScreenWalkTransitionData Params)
	{	
		bHasFinishedTransition = false;
		ParamData = Params;
		TransitionComp.bTransition = false;
		Params.Plane.StartPlaneTransition(0.25);
		Player.BlockCapabilities(CapabilityTags::Movement,this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bHasFinishedTransition)
			FinishTransition();
	}

	void FinishTransition()
	{
		bHasFinishedTransition = true;
		
		if(Player.HasActorBegunPlay())
			Player.TeleportToRespawnPoint(ParamData.EndPosition,this);

		Player.UnblockCapabilities(CapabilityTags::Movement,this);
		Player.ActivateCamera(ParamData.Camera,0.0,this, EHazeCameraPriority::High);
		Player.ClearPlayerVariantOverride(this);
		Player.ApplyPlayerVariantOverride(ParamData.Outfit, this, EInstigatePriority::High);
		ParamData.OnCompleted.ExecuteIfBound();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//If Remote has not finished in time
		if(ActiveDuration > 0.2 && !bHasFinishedTransition)
			FinishTransition();
		
	}
	
	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearPlayerVariantOverride(this);
	}

	
};