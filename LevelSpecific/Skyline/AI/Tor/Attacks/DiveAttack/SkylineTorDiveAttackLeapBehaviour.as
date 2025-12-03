class USkylineTorDiveAttackLeapBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(SkylineTorAttackTags::DiveAttack);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorDealDamageComponent DealDamageComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineTorDiveAttackComponent DiveAttackComp;
	USkylineTorTelegraphLightComponent TelegraphLightComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;

	bool bLeapStarted;
	bool bLandStarted;
	bool bRecoveryStarted;

	int AttackCounter;
	int AttackMax = 3;

	float LeapDuration;
	float LandDuration;
	float RecoveryDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		DealDamageComp = USkylineTorDealDamageComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		DiveAttackComp = USkylineTorDiveAttackComponent::GetOrCreate(Owner);
		TelegraphLightComp = USkylineTorTelegraphLightComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		LeapDuration = AnimInstance.DiveAttackLeap.Sequence.PlayLength;
		LandDuration = AnimInstance.DiveAttackLeapLand.Sequence.PlayLength;
		RecoveryDuration = AnimInstance.DiveAttackRecovery.Sequence.PlayLength;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > LeapDuration + LandDuration + RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		UBasicAIMovementSettings::SetTurnDuration(Owner, 1, this);
		Owner.BlockCapabilities(n"Hover", this);

		if (!TargetComp.HasValidTarget())
		{
			USkylineTorEventHandler::Trigger_OnDiveAttackLeapInterrupt(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
			DeactivateBehaviour();
			return;
		}

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);

		FVector Move = (DiveAttackComp.LeapAttackLocation - Owner.ActorLocation);
		AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::Leap, EBasicBehaviourPriority::Medium, this, 0.0, Move);

		USkylineTorEventHandler::Trigger_OnDiveAttackLeapStart(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		TelegraphLightComp.Start(DiveAttackComp.LeapAttackLocation);
		bLeapStarted = false;
		bLandStarted = false;
		bRecoveryStarted = false;
		DealDamageComp.ResetDamage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);
		AttackCounter = 0;
		Owner.ClearSettingsByInstigator(this);
		Owner.UnblockCapabilities(n"Hover", this);

		if(!bRecoveryStarted)
			USkylineTorEventHandler::Trigger_OnDiveAttackLeapLandStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		USkylineTorEventHandler::Trigger_OnDiveAttackLeapStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		TelegraphLightComp.Stop();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Recovery
		if(ActiveDuration > LeapDuration + LandDuration)
		{
			if(!bRecoveryStarted)
			{
				bRecoveryStarted = true;
				AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::Recovery, EBasicBehaviourPriority::Medium, this, 0.0, FVector::ZeroVector);
				USkylineTorEventHandler::Trigger_OnDiveAttackLeapLandStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
			}
			return;
		}

		// Land
		if(ActiveDuration > LeapDuration)
		{
			if(!bLandStarted)
			{
				bLandStarted = true;
				AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::LeapLand, EBasicBehaviourPriority::Medium, this, 0.0, FVector::ZeroVector);
				USkylineTorEventHandler::Trigger_OnDiveAttackLeapLandStart(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
				TelegraphLightComp.Stop();
			}
		}

		// Action
		if(!bLeapStarted)
		{
			bLeapStarted = true;
		}

		// Damage
		DealDamageComp.DealHammerDamage(0.5, ESkylineTorDealDamageDirection::Away);
		DealDamageComp.DealBodyDamage(0.5, ESkylineTorDealDamageDirection::Away);
	}
}