class USkylineTorDiveAttackBehaviour : UBasicBehaviour
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
	USkylineTorThrusterManagerComponent ThrusterManagerComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineTorDiveAttackComponent DiveAttackComp;
	USkylineTorTargetingComponent TorTargetingComp;
	USkylineTorTelegraphLightComponent TelegraphLightComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;
	int AttackIndex;

	bool bTelegraphing;
	bool bAction;

	float LandTime;
	int AttackCounter;
	int AttackMax = 3;

	float TelegraphDuration;
	float DiveDuration;
	float LandDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		DealDamageComp = USkylineTorDealDamageComponent::GetOrCreate(Owner);
		ThrusterManagerComp = USkylineTorThrusterManagerComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		DiveAttackComp = USkylineTorDiveAttackComponent::GetOrCreate(Owner);
		TorTargetingComp = USkylineTorTargetingComponent::GetOrCreate(Owner);
		TelegraphLightComp = USkylineTorTelegraphLightComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		TelegraphDuration = AnimInstance.DiveAttackTelegraph.Sequence.PlayLength;
		DiveDuration = AnimInstance.DiveAttackDive.Sequence.PlayLength;
		LandDuration = AnimInstance.DiveAttackLand.Sequence.PlayLength;

		AttackIndex = TorBehaviourComp.GetNewAttackIndex(Outer.Name);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(AttackIndex != TorBehaviourComp.GetAttackIndex(Outer.Name))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 10)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::Telegraph, EBasicBehaviourPriority::Medium, this);
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		USkylineTorEventHandler::Trigger_OnDiveAttackTelegraphStart(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		TelegraphLightComp.Start(DiveAttackComp.AttackLocation);
		bTelegraphing = true;
		bAction = false;
		LandTime = 0;
		UBasicAIMovementSettings::SetTurnDuration(Owner, 1, this);
		UMovementGravitySettings::SetGravityScale(Owner, 0, this);
		DealDamageComp.ResetDamage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnDiveAttackDiveStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		USkylineTorEventHandler::Trigger_OnDiveAttackTelegraphStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		USkylineTorEventHandler::Trigger_OnDiveAttackLandStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
		TelegraphLightComp.Stop();

		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);
		Character.MeshOffsetComponent.RelativeRotation = FRotator::ZeroRotator;
		AttackCounter = 0;
		Owner.ClearSettingsByInstigator(this);
		ThrusterManagerComp.StopThrusters(this);

		if(bAction)
			Owner.UnblockCapabilities(n"Hover", this);

		TorBehaviourComp.IncrementAttackIndex(Outer.Name);

		if(HasControl())
			CrumbSetLeapLocation(TorTargetingComp.GetPlayerLocation(Target));
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetLeapLocation(FVector LeapLocation)
	{
		DiveAttackComp.LeapAttackLocation = LeapLocation;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetAttackLocation(FVector LeapLocation)
	{
		DiveAttackComp.AttackLocation = LeapLocation;
		bTelegraphing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Recovery
		if(LandTime != 0)
		{
			DestinationComp.RotateTowards(Target);
			DiveAttackComp.LeapAttackLocation = TorTargetingComp.GetPlayerLocation(Target);
			TelegraphLightComp.Update(DiveAttackComp.LeapAttackLocation);
			if(Time::GetGameTimeSince(LandTime) > LandDuration)
				DeactivateBehaviour();
			return;
		}

		if(bTelegraphing && ActiveDuration < TelegraphDuration)
		{
			AnimComp.RequestSubFeature(SubTagSkylineTorDiveAttack::Telegraph, this);
			DestinationComp.RotateTowards(Target);
			DiveAttackComp.AttackLocation = TorTargetingComp.GetPlayerLocation(Target);
			TelegraphLightComp.Update(DiveAttackComp.AttackLocation);
			Character.MeshOffsetComponent.WorldRotation = (DiveAttackComp.AttackLocation - Owner.ActorLocation).Rotation();
			return;
		}
		
		if(bTelegraphing)
		{
			USkylineTorEventHandler::Trigger_OnDiveAttackTelegraphStop(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
			if(HasControl())
				CrumbSetAttackLocation(TorTargetingComp.GetPlayerLocation(Target));
			return;
		}

		if(ActiveDuration > TelegraphDuration + DiveDuration)
		{
			Character.MeshOffsetComponent.RelativeRotation = FRotator::ZeroRotator;
			AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::Land, EBasicBehaviourPriority::Medium, this, 0.0, FVector::ZeroVector);
			Target = Target.OtherPlayer;
			LandTime = Time::GameTimeSeconds;
			ThrusterManagerComp.StopThrusters(this);
			MoveComp.Reset();
			Owner.ActorVelocity = FVector::ZeroVector;
			USkylineTorEventHandler::Trigger_OnDiveAttackLandStart(Owner, FSkylineTorEventHandlerOnDiveAttackLandStartData(HoldHammerComp.Hammer, DiveAttackComp));
			return;
		}

		// Action
		if(!bAction)
		{
			bAction = true;
			FVector Move = DiveAttackComp.AttackLocation - Owner.ActorLocation;
			AnimComp.RequestFeature(FeatureTagSkylineTor::DiveAttack, SubTagSkylineTorDiveAttack::Dive, EBasicBehaviourPriority::Medium, this, 0.0, Move);
			Owner.BlockCapabilities(n"Hover", this);
			USkylineTorEventHandler::Trigger_OnDiveAttackDiveStart(Owner, FSkylineTorEventHandlerDiveAttackData(HoldHammerComp.Hammer, DiveAttackComp));
			ThrusterManagerComp.StartThrusters(this);
		}

		// Damage
		DealDamageComp.DealHammerDamage(0.5, ESkylineTorDealDamageDirection::Away);
		DealDamageComp.DealBodyDamage(0.5, ESkylineTorDealDamageDirection::Away);
	}
}