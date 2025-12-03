class UIslandWalkerSuspensionCableUpdateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WalkerSuspensionCables");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	
	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent WalkerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WalkerComp.UpdateCables(DeltaTime);
	}
}