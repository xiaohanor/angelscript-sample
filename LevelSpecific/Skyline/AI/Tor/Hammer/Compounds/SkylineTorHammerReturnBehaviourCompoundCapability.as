class USkylineTorHammerReturnBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UBasicAITargetingComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Return)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Return)
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
		ResetCompoundNodes();
		Owner.RemoveActorCollisionBlock(this);
		Cast<ASkylineTorHammer>(Owner).ShieldMesh.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()
			.Try(USkylineTorHammerReturnBehaviour())
			;
	}
}