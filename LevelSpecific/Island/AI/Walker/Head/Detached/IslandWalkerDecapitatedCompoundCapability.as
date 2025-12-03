// Deprecated, we are disabled after decapitated cutscene
class UIslandWalkerDecapitatedBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent SuspendComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
		SuspendComp = UIslandWalkerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if ((PhaseComp.Phase != EIslandWalkerPhase::Decapitated) && 
			(PhaseComp.Phase != EIslandWalkerPhase::Swimming) && 
			(PhaseComp.Phase != EIslandWalkerPhase::Destroyed))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if ((PhaseComp.Phase != EIslandWalkerPhase::Decapitated) && 
			(PhaseComp.Phase != EIslandWalkerPhase::Swimming) && 
			(PhaseComp.Phase != EIslandWalkerPhase::Destroyed))
			return true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				;
	}
}

