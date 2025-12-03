class UTundraBossBreakFreeCapability : UTundraBossChildCapability
{
	float MaxWaitDuration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::BreakFree)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::BreakFree)
			return true;

		if(ActiveDuration >= MaxWaitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MaxWaitDuration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::GetBackUp);
		Boss.RequestAnimation(ETundraBossAttackAnim::GetBackUp);

		if(HasControl())
			CrumbSetZoeControlSide(Boss.CurrentPhase, Boss.CurrentPhaseAttackStruct, Boss.State);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::BreakFree);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetZoeControlSide(ETundraBossPhases SyncedCurrentPhase, FTundraBossAttackQueueStruct SyncedCurrentPhaseAttackStruct, ETundraBossStates SyncedState)
	{
		Boss.SetActorControlSide(Game::Zoe);
		
		if(!Game::Zoe.HasControl())
			return;

		Boss.State = SyncedState;
		Boss.CurrentPhase = SyncedCurrentPhase;
		Boss.CurrentPhaseAttackStruct = SyncedCurrentPhaseAttackStruct;
	}
};