class USkylineTorHoveringPhaseBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default CapabilityTags.Add(n"Phase");

	USkylineTorPhaseComponent PhaseComp;
	UBasicAITargetingComponent TargetComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	UBasicAIAnimationComponent AnimComp;
	USkylineTorCollisionComponent TorCollisionComp;
	USkylineTorExposedComponent ExposedComp;
	USkylineTorOpportunityAttackComponent TorOpportunityAttackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		TorCollisionComp = USkylineTorCollisionComponent::GetOrCreate(Owner);
		ExposedComp = USkylineTorExposedComponent::GetOrCreate(Owner);
		TorOpportunityAttackComp = USkylineTorOpportunityAttackComponent::GetOrCreate(Owner);
	}

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != ESkylineTorPhase::Hovering)
			return false;
		if(PhaseComp.SubPhase != ESkylineTorSubPhase::None)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != ESkylineTorPhase::Hovering)
			return true;
		if(PhaseComp.SubPhase != ESkylineTorSubPhase::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HoldHammerComp.Hammer.HammerComp.Recall();
		Owner.BlockCapabilities(n"SplineMovement", this);
		TorCollisionComp.EnableArenaBounds(this);
		ExposedComp.Start(this);
		TorOpportunityAttackComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.UnblockCapabilities(n"SplineMovement", this);
		TorCollisionComp.ClearArenaBounds(this);
		ExposedComp.Reset(this);
		TorOpportunityAttackComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()
			.Try(USkylineTorExposedBehaviour())
			.Try(UHazeCompoundRunAll()
				.Add(USkylineTorHoverBehaviour())
				.Add(USkylineTorStolenIdleBehaviour())
				.Add(USkylineTorSetTargetBehaviour())
				.Add(UHazeCompoundStatePicker()
					.State(USkylineTorAttackCooldownBehaviour())
					.State(UHazeCompoundSequence()
						.Then(USkylineTorDiveAttackBehaviour())
						.Then(USkylineTorDiveAttackLeapBehaviour())
					)
					.State(USkylineTorHoldHammerVolleyBehaviour())
				)
				.Add(UHazeCompoundStatePicker()
					.State(USkylineTorRecallHammerBehaviour())
					.State(USkylineTorPulseAttackBehaviour())
				)
				.Add(USkylineTorIdleBehaviour())
				.Add(UBasicTrackTargetBehaviour())
			);
	}
}