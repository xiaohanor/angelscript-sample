class UTundraBossSpawnLastPhaseCapability : UTundraBossChildCapability
{
	float Duration = 1.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::SpawnLastPhase)
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
		Boss.SetActorLocationAndRotation(Boss.LastPhasePositionActor.ActorLocation, Boss.LastPhasePositionActor.ActorRotation, true);
		Boss.RequestAnimation(ETundraBossAttackAnim::Idle, true);
		Boss.SetActorHiddenInGame(false);
		Boss.OnAttackEventHandler(Duration);
		
		if(HasControl())
			Boss.CrumbUpdateTundraBossHealthSettings(Boss.AttackPhases.FindOrAdd(Boss.CurrentPhase).HealthDuringPhase);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boss.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::SpawnLastPhase);
	}
};