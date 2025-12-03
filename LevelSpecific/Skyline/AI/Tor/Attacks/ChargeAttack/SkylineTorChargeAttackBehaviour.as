
class USkylineTorChargeAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(SkylineTorAttackTags::ChargeAttack);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorDealDamageComponent DealDamageComp;
	USkylineTorThrusterManagerComponent ThrusterManagerComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineTorHoverComponent HoverComp;
	USkylineTorBehaviourComponent TorBehaviourComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazePlayerCharacter Target;
	private AHazeCharacter Character;

	FBasicAIAnimationActionDurations Durations;

	bool bTelegraping;
	bool bAction;

	float RecoverTime;
	float AttackDuration;
	int AttackCounter;
	int AttackMax = 3;
	float AttackStartTime;

	FVector AttackDirection;
	int AttackIndex;

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
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		Durations.Telegraph = AnimInstance.ChargeAttackTelegraph.Sequence.PlayLength;
		Durations.Anticipation = AnimInstance.ChargeAttackAnticipation.Sequence.PlayLength;
		Durations.Action = AnimInstance.ChargeAttackAction.Sequence.PlayLength;
		Durations.Recovery = AnimInstance.ChargeAttackRecover.Sequence.PlayLength * 0.5;

		AttackIndex = TorBehaviourComp.GetNewAttackIndex(Outer.Name);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(AttackIndex != TorBehaviourComp.GetAttackIndex(Outer.Name))
			return false;
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagSkylineTor::ChargeAttack, EBasicBehaviourPriority::Medium, this);
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		USkylineTorEventHandler::Trigger_OnChargeAttackTelegraphStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		bTelegraping = true;
		AttackDuration = 0;
		AttackReset();
		UBasicAIMovementSettings::SetTurnDuration(Owner, 1, this);
		DealDamageComp.ResetDamage();
		DamageComp.bDisableRecoil.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnChargeAttackStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		USkylineTorEventHandler::Trigger_OnChargeAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(PlayerTarget != nullptr)
			TargetComp.SetTarget(PlayerTarget.OtherPlayer);
		AttackCounter = 0;
		UBasicAIMovementSettings::ClearTurnDuration(Owner, this);
		ThrusterManagerComp.StopThrusters(this);
		DamageComp.bDisableRecoil.Clear(this);
		HoverComp.ClearHover(this);
		TorBehaviourComp.IncrementAttackIndex(Outer.Name);
	}

	private void AttackReset()
	{
		bAction = false;
		DealDamageComp.HitTargets.Empty();		
		RecoverTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AttackDuration += DeltaTime;

		// Recovery
		if(RecoverTime != 0)
		{
			AnimComp.RequestSubFeature(SubTagSkylineTorChargeAttack::Recover, this, Durations.Recovery);
			DestinationComp.RotateTowards(Target);

			if(Time::GetGameTimeSince(RecoverTime) > Durations.Recovery)
				DeactivateBehaviour();
			return;
		}

		if(Durations.IsInTelegraphRange(AttackDuration))
		{
			AnimComp.RequestSubFeature(SubTagSkylineTorChargeAttack::Telegraph, this);
			DestinationComp.RotateTowards(Target);
			AttackDirection = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
			return;
		}
		
		if(bTelegraping)
		{
			bTelegraping = false;
			HoverComp.StopHover(this, EInstigatePriority::High);
		}

		if(Durations.IsInAnticipationRange(AttackDuration))
		{
			AnimComp.RequestSubFeature(SubTagSkylineTorChargeAttack::Anticipation, this);
			DestinationComp.RotateTowards(Target);
			AttackDirection = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
			return;
		}

		FVector TargetLocation = Owner.ActorLocation + AttackDirection * 250;

		FVector MeshLocation = FVector::ZeroVector;
		bool bStopAttack = !Pathfinding::FindNavmeshLocation(TargetLocation, 100, 500, MeshLocation);
		if(!bStopAttack)
			bStopAttack = !Pathfinding::StraightPathExists(Owner.ActorLocation, MeshLocation);
		if(bStopAttack)
		{
			USkylineTorEventHandler::Trigger_OnChargeAttackStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			Owner.ActorVelocity = FVector::ZeroVector;
			MoveComp.Reset();

			Target = Target.OtherPlayer;
			AttackCounter++;
			if(AttackCounter >= AttackMax)			
			{
				RecoverTime = Time::GameTimeSeconds;
			}
			else 
			{
				AttackReset();
				AttackDuration = Durations.Telegraph;
				USkylineTorEventHandler::Trigger_OnChargeAttackTelegraphStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			}
			ThrusterManagerComp.StopThrusters(this);
			return;
		}

		// Action
		AnimComp.RequestSubFeature(SubTagSkylineTorChargeAttack::Action, this);
		if(!bAction)
		{
			bAction = true;
			USkylineTorEventHandler::Trigger_OnChargeAttackStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			USkylineTorEventHandler::Trigger_OnChargeAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
			ThrusterManagerComp.StartThrusters(this);
			AttackStartTime = ActiveDuration;
		}

		// Move
		float MoveSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(3000.0, 2000.0), ActiveDuration - AttackStartTime);
		DestinationComp.MoveTowards(TargetLocation, MoveSpeed);

		// Damage
		TArray<FHitResult> HammerHits = DealDamageComp.DealHammerDamage(0.5, ESkylineTorDealDamageDirection::Side);
		for(FHitResult Hit : HammerHits)
			USkylineTorEventHandler::Trigger_OnChargeAttackHit(Owner, FSkylineTorEventHandlerHitData(HoldHammerComp.Hammer, Hit));
		
		TArray<FHitResult> BodyHits = DealDamageComp.DealBodyDamage(0.5, ESkylineTorDealDamageDirection::Side);
		for(FHitResult Hit : BodyHits)
			USkylineTorEventHandler::Trigger_OnChargeAttackHit(Owner, FSkylineTorEventHandlerHitData(HoldHammerComp.Hammer, Hit));
		
	}
}