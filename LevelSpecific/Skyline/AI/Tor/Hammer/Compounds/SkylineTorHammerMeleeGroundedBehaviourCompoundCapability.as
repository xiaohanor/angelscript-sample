class USkylineTorHammerMeleeGroundedBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UBasicAITargetingComponent TargetComp;
	UGravityWhipResponseComponent WhipResponse;
	USkylineTorHammerGrabMashComponent GrabMashComp;
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
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);

		BladeResponse = UGravityBladeCombatResponseComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"BladeHit");

		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnStartGrabSequence.AddUFunction(this, n"StartGrab");
		WhipResponse.OnEndGrabSequence.AddUFunction(this, n"EndGrab");

		DisableInstigator = FInstigator(n"HammerMeleeGroundedInstigator");
	}

	UFUNCTION()
	private void BladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		BladeHitTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeGrounded)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeGrounded)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PivotComp.RemovePivot();
		TargetComp.SetTarget(Game::Zoe);
		Owner.UnblockCapabilities(n"GroundMovement", Owner);
		OriginalMashDuration = WhipResponse.ButtonMashSettings.Duration;
		WhipResponse.ButtonMashSettings.Duration = 2;
		StealComp.EnableStealing(DisableInstigator, 10, -1, 0.1);
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
				.Add(USkylineTorHammerMoveBehaviour())
				.Add(USkylineTorHammerPassiveBehaviour())
			);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HammerComp.bBlockReturn && StealComp.IsStealingExpired() && Time::GetGameTimeSince(BladeHitTime) > 0.5)
			HammerComp.Recall();
	}

	UFUNCTION()
	private void StartGrab()
	{
		if(!IsActive())
			return;
		UBasicAISettings::SetChaseMoveSpeed(Owner, 250, this);
	}

	UFUNCTION()
	private void EndGrab()
	{
		if(!IsActive())
			return;
		UBasicAISettings::ClearChaseMoveSpeed(Owner,  this);
	}
}

