class UTundraBossBreakingIceCapability : UTundraBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::BreakingIce)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::BreakingIce)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!HasControl())
			return;

		if(Boss.bSkipBreakIce)
		{
			//This deactivates the capability immediately. Only used when respawning from Phase03 (the one with cutscene) progress point.
			Boss.CrumbPushAttack(ETundraBossStates::Hidden);
			return;
		}		

		//This Capability doesn't deactivate on its own when bSkipBreakIce is false. Instead, we're setting the state to Hidden from Level BP when the SEQ is completed.
		CrumbPlayBreakIceSeq();
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayBreakIceSeq()
	{
		Boss.OnPlayBreakIceSequence.Broadcast();
		Boss.OnAttackEventHandler(-1);
	}
}