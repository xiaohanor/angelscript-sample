// This is only activated if Ice King should get back up after being hit by a sphere but has NOT taken punch damage. Meaning the Monkey didn't punch Ice King in time after being hit by a sphere. 
class UTundraBossGetBackUpFromSphereCapability : UTundraBossChildCapability
{
	float Duration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::GetBackUpAfterSphere)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::GetBackUpAfterSphere)
			return true;

		if(ActiveDuration >= Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::GetBackUpPhase03);

		Boss.RequestAnimation(ETundraBossAttackAnim::GetBackUpPhase03);
		Boss.OnAttackEventHandler(Duration);

		if(HasControl())
			CrumbSetZoeControlSide(Boss.CurrentPhase, Boss.CurrentPhaseAttackStruct, Boss.State);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.OnGotBackUpFromSphereHit.Broadcast();
		Boss.CapabilityStopped(ETundraBossStates::GetBackUpAfterSphere);
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