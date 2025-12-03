class USkylineTorHammerRecallCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.bRecall)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.bRecall)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.AddActorCollisionBlock(this);
		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.RemoveActorCollisionBlock(this);
	}
}