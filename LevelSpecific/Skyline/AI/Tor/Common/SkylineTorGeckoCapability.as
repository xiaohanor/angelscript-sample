
class USkylineTorGeckoCapability : UHazeCapability
{
	USkylineTorPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Gecko)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.Phase != ESkylineTorPhase::Gecko)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.RemoveActorCollisionBlock(this);
	}
}