class UTundraBossReturnAfterFirstSphereHitCapability : UTundraBossChildCapability
{
	float Duration = 1.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::ReturnAfterFirstSphereHit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.HitByFirstSphereSequencer.OnSequenceSkippedEvent.AddUFunction(this, n"SeqSkipped");
		Duration = Boss.HitByFirstSphereSequencer.DurationAsSeconds + 1;
		
		Boss.RequestAnimation(ETundraBossAttackAnim::Idle, true);
		Boss.SetActorHiddenInGame(false);
		Boss.OnPlayHitByFirstSphereSequence.Broadcast();
		Boss.OnAttackEventHandler(Duration);
	}

	UFUNCTION()
	private void SeqSkipped(float32 PositionWhenSkipped)
	{
		//Deactivates the capability
		Duration = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.HitByFirstSphereSequencer.OnSequenceSkippedEvent.Unbind(this, n"SeqSkipped");
		Boss.CapabilityStopped(ETundraBossStates::ReturnAfterFirstSphereHit);
	}
};