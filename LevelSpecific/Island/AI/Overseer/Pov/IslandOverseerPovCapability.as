class UIslandOverseerPovCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerPovComponent PovComp;
	AAIIslandOverseer Overseer;
	bool bChangePhase;
	bool bShutdown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
		PovComp = UIslandOverseerPovComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::PovCombat)
			return false;
		if(bChangePhase)
			return false;
		if(PovComp.PovWidget == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bChangePhase)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bShutdown = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Overseer.HealthComp.SetCurrentHealth(PhaseComp.PovCombatHealthThreshold);
		Overseer.HealthBarComp.SnapBarToHealth();
		PhaseComp.Phase = EIslandOverseerPhase::Idle;

		if(!bShutdown)
			PovComp.PovWidget.OnShutdown();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bShutdown)
			return;

		if(Overseer.HealthComp.CurrentHealth > PhaseComp.PovCombatHealthThreshold)
			return;

		bShutdown = true;
		PovComp.PovWidget.OnShutdownCompleted.AddUFunction(this, n"ShutdownCompleted");
		PovComp.PovWidget.OnShutdown();
	}

	UFUNCTION()
	private void ShutdownCompleted()
	{
		bChangePhase = true;
	}
}