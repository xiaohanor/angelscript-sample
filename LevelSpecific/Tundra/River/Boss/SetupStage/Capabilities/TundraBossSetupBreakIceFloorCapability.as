class UTundraBossSetupBreakIceFloorCapability : UTundraBossSetupChildCapability
{
	float Duration = 2.75;
	bool bShouldAttackMio = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossSetupStates::BreakIceFloor)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTundraBossSetup_EffectHandler::Trigger_OnBreakIceFloor(Boss);

		if(!HasControl())
			return;

		AHazePlayerCharacter TargetPlayer = bShouldAttackMio ? Game::Mio : Game::Zoe;
		int PlatformIndex = Boss.IceFloorNew.GetPlayersPlatformIndex(TargetPlayer, false, true);
		TArray<ATundraBossSetupDestroyIceAttackActor> BreakIceFloorActors = Boss.IceFloorNew.DestroyIceAttackActors;
		ATundraBossSetupDestroyIceAttackActor BreakIceFloorActor = ReturnDestroyIceAttackActorBasedOnPlatformIndex(PlatformIndex, BreakIceFloorActors);


		ETundraBossSetupAttackAnim AnimToPlay = ReturnAnimBasedOnPlatformIndex(PlatformIndex);

		Boss.CrumbActivateBreakIceAttack(AnimToPlay, BreakIceFloorActor.ActorTransform, PlatformIndex);

		bShouldAttackMio = !bShouldAttackMio;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ATundraBossSetupBreakIceFloorManager Manager = TundraBossSetupBreakIceFloorManager::GetBreakIceFloorManager();
		if(Manager != nullptr)
			Manager.ProgressBreakIceFloorIteration();
		
		if (HasControl())
			Boss.CrumbProgressQueue();
	}

	ATundraBossSetupDestroyIceAttackActor ReturnDestroyIceAttackActorBasedOnPlatformIndex(int Index, TArray<ATundraBossSetupDestroyIceAttackActor> Array)
	{
		for(auto DestroyIceActor : Array)
		{
			if(DestroyIceActor.PlatformIndex == Index)
				return DestroyIceActor;
		}

		return nullptr;
	}

	ETundraBossSetupAttackAnim ReturnAnimBasedOnPlatformIndex(int Index)
	{
		switch(Index)
		{
			case 0:
				return ETundraBossSetupAttackAnim::None;
			case 1:
				return ETundraBossSetupAttackAnim::BreakFromUnderIce;
			case 2:
				return ETundraBossSetupAttackAnim::BreakFromUnderIce;
			case 3:
				return ETundraBossSetupAttackAnim::BreakIce;
			case 4:
				return ETundraBossSetupAttackAnim::BreakFromUnderIce;
			default:
				return ETundraBossSetupAttackAnim::None;
			
		}
	}
};