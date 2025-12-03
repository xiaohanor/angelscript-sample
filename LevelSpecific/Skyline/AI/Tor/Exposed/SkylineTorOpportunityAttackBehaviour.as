class USkylineTorOpportunityAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackComp;
	USkylineTorOpportunityAttackComponent TorOpportunityAttackComp;
	USkylineTorOpportunityAttackCameraComponent Camera;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	UCombatHitStopComponent HitStopComp;
	UCombatHitStopComponent AttackerHitStopComp;
	USkylineTorHoverComponent HoverComp;
	USkylineTorSettings Settings;

	AHazeCharacter Character;
	AHazePlayerCharacter OpportunityAttackPlayer;
	UGravityBladePlayerOpportunityAttackComponent OpportunityAttackerComp;

	int NumStartedAttacks = 0;
	float LastHitTime;
	float DamagePerHit = 0.0;
	int SegmentHitCount = 0;
	float NextHitTime = BIG_NUMBER;
	float CompleteTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();				
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		OpportunityAttackComp = UGravityBladeOpportunityAttackTargetComponent::GetOrCreate(Owner);
		TorOpportunityAttackComp = USkylineTorOpportunityAttackComponent::GetOrCreate(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		Camera = USkylineTorOpportunityAttackCameraComponent::Get(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);

		OpportunityAttackComp.OnOpportunityAttackBegin.AddUFunction(this, n"OnBegin");
		OpportunityAttackComp.OnOpportunityAttackCompleted.AddUFunction(this, n"OnCompleted");
		OpportunityAttackComp.OnOpportunityAttackFailed.AddUFunction(this, n"OnFailed");
		OpportunityAttackComp.OnOpportunityAttackSegmentStart.AddUFunction(this, n"OnAttackSegmentStart");
		OpportunityAttackComp.OnOpportunityAttackStartFailing.AddUFunction(this, n"OnStartFailing");

		OpportunityAttackComp.DurationUntilFail = Settings.OpportunityAttackDurationUntilFail;
	}

	UFUNCTION()
	private void OnBegin(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp)
	{
		if(!TorOpportunityAttackComp.bCanStartSequence)
			return;
		OpportunityAttackerComp = PlayerOpportunityAttackComp;
		OpportunityAttackPlayer = Cast<AHazePlayerCharacter>(PlayerOpportunityAttackComp.Owner);
		TorOpportunityAttackComp.bStartedSequence = true;
	}

	UFUNCTION()
	private void OnAttackSegmentStart(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp)
	{
		if (!TorOpportunityAttackComp.bCanStartSequence)
			return;
		if (!ensure(OpportunityAttackerComp != nullptr && OpportunityAttackPlayer != nullptr))
			return;

		// Activate custom camera for opportunity sequence 
		if (OpportunityAttackerComp.CurrentSegment == 0)
			Camera.StartAttackSequence(OpportunityAttackPlayer);
		float BlendTime = 0.2;
		OpportunityAttackPlayer.DeactivateCameraByInstigator(this);
		OpportunityAttackPlayer.ActivateCamera(Camera, BlendTime, this, EHazeCameraPriority::VeryHigh);

		OpportunityAttackPlayer.ClearCameraSettingsByInstigator(this);
		UHazeCameraSpringArmSettingsDataAsset CamSettings = TorOpportunityAttackComp.GetAttackCameraSettings(OpportunityAttackerComp.CurrentSegment);
		OpportunityAttackPlayer.ApplyCameraSettings(CamSettings, 1.0, this, EHazeCameraPriority::High);

		NumStartedAttacks++;

		SegmentHitCount = 0;
		NextHitTime = GetNextHitTime();
	}

	UFUNCTION()
	private void OnCompleted(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp)
	{
		if(!IsActive())
			return;
		if (!ensure(OpportunityAttackerComp != nullptr && OpportunityAttackPlayer != nullptr))
			return;

		if(PhaseComp.Phase == ESkylineTorPhase::Grounded)
			PhaseComp.SetPhase(ESkylineTorPhase::Gecko);

		// This is triggered when attackers attack animation is done playing.
		// Delay completion until our response is also done playing.
		FOpportunityAttackSegment Segment = OpportunityAttackerComp.GetCurrentSegment();		
		CompleteTime = ActiveDuration + Segment.TargetAttackResponse.Sequence.ScaledPlayLength - Segment.Attack.Sequence.ScaledPlayLength;
	}

	UFUNCTION()
	private void OnStartFailing(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp)
	{
		if(!IsActive())
			return;
		if (!ensure(OpportunityAttackerComp != nullptr && OpportunityAttackPlayer != nullptr))
			return;

		// Fail camera
		OpportunityAttackPlayer.ClearCameraSettingsByInstigator(this);
		UHazeCameraSpringArmSettingsDataAsset CamSettings = TorOpportunityAttackComp.GetFailCameraSettings(OpportunityAttackerComp.CurrentSegment);
		OpportunityAttackPlayer.ApplyCameraSettings(CamSettings, 3.0, this, EHazeCameraPriority::High);
	}

	UFUNCTION()
	private void OnFailed(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp)
	{
		if(!IsActive())
			return;
		if (!ensure(OpportunityAttackerComp != nullptr && OpportunityAttackPlayer != nullptr))
			return;

		// This is triggered when attackers fail animation is done playing.
		// Delay completion until slightly after our response is also done playing.
		FOpportunityAttackSegment Segment = OpportunityAttackerComp.GetCurrentSegment();		
		CompleteTime = ActiveDuration + Segment.TargetFailResponse.Sequence.ScaledPlayLength - Segment.Fail.Sequence.ScaledPlayLength + Settings.OpportunityAttackPauseAfterFail;

		float RecoverHealth = 0.25;
		HealthComp.SetCurrentHealth(RecoverHealth);
		HealthBarComp.UpdateHealthBarSettings();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TorOpportunityAttackComp.bStartedSequence)
			return false;
		if(OpportunityAttackPlayer == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > CompleteTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TorOpportunityAttackComp.bIsOpportunityAttackSequenceActive = true;
		HoverComp.StopHover(this, EInstigatePriority::High);

		TorOpportunityAttackComp.bStartedSequence = false;

		AnimComp.RequestFeature(FeatureTagSkylineTor::OpportunityAttack, EBasicBehaviourPriority::Medium, this);
		NumStartedAttacks = 0;
		DamageComp.bDisableRecoil.Apply(true, this);

		OpportunityAttackPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
		OpportunityAttackPlayer.HealPlayerHealth(1);

		OpportunityAttackPlayer.OtherPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
		OpportunityAttackPlayer.OtherPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);

		DamagePerHit = GetDamagePerHit();
		SegmentHitCount = 0;
		NextHitTime = GetNextHitTime();
		LastHitTime = -BIG_NUMBER;

		CompleteTime = BIG_NUMBER;

		AttackerHitStopComp = UCombatHitStopComponent::Get(OpportunityAttackPlayer);
		if (!Settings.OpportunityAttackAllowHitStops)
		{
			HitStopComp.Disable(this);
			AttackerHitStopComp.Disable(this);			
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DamageComp.bDisableRecoil.Clear(this);
		OpportunityAttackComp.DisableOpportunityAttack();
		NumStartedAttacks = 0;

		OpportunityAttackPlayer.OtherPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
		OpportunityAttackPlayer.OtherPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		OpportunityAttackPlayer.DeactivateCameraByInstigator(this);
		OpportunityAttackPlayer.ClearCameraSettingsByInstigator(this);
		OpportunityAttackPlayer.ClearPointOfInterestByInstigator(this);
		OpportunityAttackPlayer = nullptr;

		HitStopComp.Enable(this);
		AttackerHitStopComp.Enable(this);			

		TorOpportunityAttackComp.bIsOpportunityAttackSequenceActive = false;
		HoverComp.ClearHover(this);

		if(OpportunityAttackerComp.IsInFinalSegment())
			PhaseComp.SetPhase(ESkylineTorPhase::Dead);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > NextHitTime)
		{
			LastHitTime = ActiveDuration;
			SegmentHitCount++;
			NextHitTime = GetNextHitTime();
			if (OpportunityAttackerComp.IsInFinalSegment())
			{
				FOpportunityAttackSegment Segment = OpportunityAttackerComp.GetCurrentSegment();
				TArray<FHazeAnimNotifyStateGatherInfo> NotifyInfo;	
				Segment.Attack.Sequence.GetAnimNotifyStateTriggerTimes(UAnimNotifyGravityBladeHitWindow, NotifyInfo);
			}
			USkylineTorEventHandler::Trigger_OnOpportunityAttackImpact(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		}

		if (OpportunityAttackerComp.CurrentSegment == 0)
			Camera.Update(DeltaTime, 1.2);
		else
			Camera.Update(DeltaTime, 0.0);
	}

	float GetNextHitTime()
	{
		FOpportunityAttackSegment Segment = OpportunityAttackerComp.GetCurrentSegment();
		TArray<FHazeAnimNotifyStateGatherInfo> NotifyInfo;
		if (Segment.Attack.Sequence.GetAnimNotifyStateTriggerTimes(UAnimNotifyGravityBladeHitWindow, NotifyInfo) && (NotifyInfo.Num() > SegmentHitCount))
		{
			float LastTime = (SegmentHitCount == 0) ? 0.0 : NotifyInfo[SegmentHitCount - 1].TriggerTime;
			float Interval = NotifyInfo[SegmentHitCount].TriggerTime - LastTime;
			return ActiveDuration + (Interval / Math::Max(0.1, Segment.Attack.Sequence.RateScale));
		}
		return BIG_NUMBER; 
	}

	float GetHealthAfterSuccessfulAttackSequence() const
	{
		if(PhaseComp.Phase == ESkylineTorPhase::Hovering) 
			return 0.0; // Assuming we only have one opportunity attack in hovering phase
		if (OpportunityAttackComp.AttackSequenceIndex == 0)
			return Settings.OpportunityAttack_0.HealthAfterSuccess;
		check(false);
		return 1.0;
	}

	float GetDamagePerHit()
	{
		float HealthAfterSuccess = GetHealthAfterSuccessfulAttackSequence();
		float TotalDamage = HealthComp.CurrentHealth - HealthAfterSuccess;

		int NumHits = 0;
		FOpportunityAttackSequence AttackSequence = OpportunityAttackerComp.CurrentSequence;
		for (FOpportunityAttackSegment Segment : AttackSequence.Segments)
		{
			TArray<FHazeAnimNotifyStateGatherInfo> NotifyInfo;
			if (Segment.Attack.Sequence.GetAnimNotifyStateTriggerTimes(UAnimNotifyGravityBladeHitWindow, NotifyInfo))
				NumHits += NotifyInfo.Num();
		}
		if (ensure(NumHits > 0, "No gravity blade hit window notifies in any attack animations, no damage will be dealt in opportunity attack."))
			return TotalDamage / float(NumHits);	
		return 0.0;
	}
}