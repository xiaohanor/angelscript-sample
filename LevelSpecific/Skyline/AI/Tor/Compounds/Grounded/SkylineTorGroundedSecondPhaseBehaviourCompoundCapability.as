class USkylineTorGroundedSecondPhaseBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	

	USkylineTorPhaseComponent PhaseComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	UBasicAITargetingComponent TargetComp;
	USkylineTorCollisionComponent TorCollisionComp;
	USkylineTorPulseComponent PulseComp;
	USkylineTorExposedComponent ExposedComp;
	USkylineTorOpportunityAttackComponent TorOpportunityAttackComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		TorCollisionComp = USkylineTorCollisionComponent::GetOrCreate(Owner);
		PulseComp = USkylineTorPulseComponent::GetOrCreate(Owner);
		ExposedComp = USkylineTorExposedComponent::GetOrCreate(Owner);
		TorOpportunityAttackComp = USkylineTorOpportunityAttackComponent::GetOrCreate(Owner);
	}

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != ESkylineTorPhase::Grounded)
			return false;
		if(PhaseComp.SubPhase != ESkylineTorSubPhase::GroundedSecond)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != ESkylineTorPhase::Grounded)
			return true;
		if(PhaseComp.SubPhase != ESkylineTorSubPhase::GroundedSecond)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HoldHammerComp.Hammer.HammerComp.Recall();
		Owner.BlockCapabilities(n"SplineMovement", this);
		TargetComp.SetTarget(Game::Mio);
		TorCollisionComp.EnableArenaBounds(this);
		PulseComp.bAllowWhileNotStolen = true;
		ExposedComp.Start(this);
		TorOpportunityAttackComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.UnblockCapabilities(n"SplineMovement", this);
		TorCollisionComp.ClearArenaBounds(this);
		PulseComp.bAllowWhileNotStolen = false;
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
					.Add(USkylineTorExitLocationBehaviour())
					.Add(USkylineTorSetTargetBehaviour())
					.Add(UHazeCompoundStatePicker()
						.State(USkylineTorAttackCooldownBehaviour())
						.State(USkylineTorWhirlwindAttackBehaviour())
						.State(USkylineTorSmashAttackBehaviour())
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