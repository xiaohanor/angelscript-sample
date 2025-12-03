class USkylineTorHammerStolenCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerStolenComponent StolenComp;
	USkylineTorHammerStateManager HammerStateManager;
	USkylineTorDamageComponent TorDamageComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		StolenComp = USkylineTorHammerStolenComponent::GetOrCreate(Owner);
		HammerStateManager = USkylineTorHammerStateManager::GetOrCreate(Owner);
		TorDamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);

		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if(IsActive())
			return;
		HammerComp.SetMode(ESkylineTorHammerMode::Stolen);
		StolenComp.Steal(UserComponent);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
	                        UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if(!IsActive())
		{
			// Player must stop aiming here, even if this compound isn't active 
			// (if e.g. hammer returns on it's control side before it OnGrabbed above reaches it from Zoe's control side)
			// OnReleased will only ever trigger when hammer is taken back.
			if (StolenComp.PlayerStolenComp.bStolen)
				StolenComp.Release();
			return;
		}
		StolenComp.Release();
		HammerComp.SetMode(ESkylineTorHammerMode::Return);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Stolen)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode == ESkylineTorHammerMode::Stolen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HammerStateManager.EnableWhipTargetComp(this);
		HealthBarComp.SetHealthBarEnabled(false);
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		HammerStateManager.ClearWhipTargetComp(this);
		Owner.RemoveActorCollisionBlock(this);
		StolenComp.Release();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundRunAll()			
			.Add(USkylineTorHammerStolenAttackCapability())
			.Add(USkylineTorHammerStolenIdleCapability());
	}
}