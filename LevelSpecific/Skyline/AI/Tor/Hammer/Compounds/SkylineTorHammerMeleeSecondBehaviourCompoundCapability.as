class USkylineTorHammerMeleeSecondBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UBasicAITargetingComponent TargetComp;
	UGravityWhipResponseComponent WhipResponse;
	USkylineTorHammerGrabMashComponent GrabMashComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorHammerStealComponent StealComp;
	UGravityBladeCombatResponseComponent BladeResponse;

	float OriginalMashDuration;
	float BladeHitTime;
	FInstigator DisableInstigator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		GrabMashComp = USkylineTorHammerGrabMashComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);

		BladeResponse = UGravityBladeCombatResponseComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"BladeHit");

		DisableInstigator = FInstigator(n"HammerMeleeSecondInstigator");
	}

	UFUNCTION()
	private void BladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		BladeHitTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeSecond)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeSecond)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UBasicAISettings::SetChaseMoveSpeed(Owner, 1000, this);
		PivotComp.RemovePivot();
		TargetComp.SetTarget(Game::Zoe);
		Owner.UnblockCapabilities(n"GroundMovement", Owner);
		OriginalMashDuration = WhipResponse.ButtonMashSettings.Duration;
		WhipResponse.ButtonMashSettings.Duration = 2;
		CooldownComp.AttackCooldown.Set(0.5);
		StealComp.EnableStealing(DisableInstigator, 12, -1, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();

		Owner.BlockCapabilities(n"GroundMovement", Owner);
		UBasicAISettings::ClearChaseMoveSpeed(Owner,  this);
		WhipResponse.ButtonMashSettings.Duration = OriginalMashDuration;

		StealComp.DisableStealing(DisableInstigator);
		HammerComp.ResetTranslations();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()
			.Try(USkylineTorHammerStunnedBehaviour())
			.Try(UHazeCompoundRunAll()
				.Add(USkylineTorHammerHurtReactionBehaviour())
				.Add(UHazeCompoundStatePicker()
					.State(USkylineTorHammerChargeAttackBehaviour())
				)
				.Add(USkylineTorHammerMoveBehaviour())
				.Add(UBasicChaseBehaviour())
			);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HammerComp.bBlockReturn && StealComp.IsStealingExpired() && Time::GetGameTimeSince(BladeHitTime) > 0.5)
			HammerComp.Recall();
	}
}

