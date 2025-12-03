event void FSkylineTorOnFinishingHammerBlowStartedSignature();
class USkylineTorDamageComponent : UActorComponent
{
	UGravityBladeCombatResponseComponent BladeResponse;
	UGravityWhipResponseComponent WhipResponse;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;	
	USkylineTorHoldHammerComponent HoldHammerComp;
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackComp;
	USkylineTorPhaseComponent PhaseComp;

	FSkylineTorOnFinishingHammerBlowStartedSignature OnFinishingHammerBlowStarted;

	AHazeCharacter Character;
	USkylineTorSettings Settings;
	TInstigated<bool> bDisableRecoil;
	TInstigated<bool> bEnableDamage;

	float HurtReactionTime;
	float HeavyHurtReactionTime;
	bool bHurtReactionInterrupted;
	bool bHeavyHurtReactionInterrupted;
	float HurtReactionDuration = 0.1;

	bool bDamaged;
	const float BladeDamage = 0.025;
	const float HammerDamage = 0.075;
	const float WhipDamage = 0.005;

	int NumConsecutiveHammerHits = 0;
	bool bIsPerformingFinishingHammerBlow = false;

	FVector PreviousBodyDamageLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Character = Cast<AHazeCharacter>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		OpportunityAttackComp = UGravityBladeOpportunityAttackTargetComponent::GetOrCreate(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");	
		Settings = USkylineTorSettings::GetSettings(Cast<AHazeActor>(Owner));

		WhipResponse.OnHitByWhip.AddUFunction(this, n"WhipHit");

		USkylineTorHammerResponseComponent HammerResponse = USkylineTorHammerResponseComponent::GetOrCreate(Owner);
		if (HammerResponse != nullptr)
			HammerResponse.OnHit.AddUFunction(this, n"OnHammerHit");
	}

	UFUNCTION()
	private void WhipHit(UGravityWhipUserComponent UserComponent, EHazeCardinalDirection HitDirection,
	                     EAnimHitPitch HitPitch, float HitWindowExtraPushback,
	                     float HitWindowPushbackMultiplier)
	{
		if(!bEnableDamage.Get())
			return;
		if(OpportunityAttackComp.IsOpportunityAttackEnabled())
			return;
		
		TakeDamage(WhipDamage, EDamageType::Default, Cast<AHazeActor>(UserComponent.Owner), false);
	}

	UFUNCTION()
	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{		
		if(!bEnableDamage.Get())
			return;
		if(OpportunityAttackComp.IsOpportunityAttackEnabled())
			return;

		USkylineTorEventHandler::Trigger_OnBladeHit(Cast<AHazeActor>(Owner), FSkylineTorEventHandlerOnBladeHitData(HoldHammerComp.Hammer, HitData));
		TakeDamage(BladeDamage, EDamageType::Default, Cast<AHazeActor>(CombatComp.Owner), false);
	}

	UFUNCTION()
	private void OnHammerHit(float Damage, EDamageType DamageType, AHazeActor HammerInstigator)
	{
		// if(!bEnableDamage.Get())
		// 	return;
		if(OpportunityAttackComp.IsOpportunityAttackEnabled())
			return;
		NumConsecutiveHammerHits++;
		TakeDamage(HammerDamage, DamageType, HammerInstigator, true);
	}

	private void TakeDamage(float Damage, EDamageType DamageType, AHazeActor Instigator, bool bHeavy)
	{
		float FinalDamage = CapDamage(Damage);

		bDamaged = true;
		DamageFlash::DamageFlashActor(Owner, 0.05, FLinearColor::White);

		if(bHeavy)
		{
			bHeavyHurtReactionInterrupted = true;
			HeavyHurtReactionTime = Time::GameTimeSeconds;
		}
		else
		{
			bHurtReactionInterrupted = true;
			HurtReactionTime = Time::GameTimeSeconds;
		}

		HealthComp.TakeDamage(FinalDamage, DamageType, Instigator);
	}

	float CapDamage(float Damage)
	{
		ESkylineTorPhase Phase = PhaseComp.Phase;
		ESkylineTorSubPhase SubPhase = PhaseComp.SubPhase;

		float HealthAfterDamage = HealthComp.CurrentHealth - Damage;
		float Threshold = 0;

		if(Phase == ESkylineTorPhase::Grounded && SubPhase == ESkylineTorSubPhase::None)
			Threshold = PhaseComp.GroundedThreshold;
		if(Phase == ESkylineTorPhase::Grounded && SubPhase == ESkylineTorSubPhase::GroundedSecond)
			Threshold = PhaseComp.GroundedSecondThreshold;
		if(Phase == ESkylineTorPhase::Hovering && SubPhase == ESkylineTorSubPhase::None && HealthAfterDamage <= PhaseComp.HoveringThreshold)
			Threshold = PhaseComp.HoveringThreshold;
		if(Phase == ESkylineTorPhase::Hovering && SubPhase == ESkylineTorSubPhase::HoveringSecond && HealthAfterDamage <= PhaseComp.HoveringSecondThreshold)
			Threshold = PhaseComp.HoveringSecondThreshold;

		if(Threshold < SMALL_NUMBER)
			return Damage;

		if(Threshold < HealthAfterDamage)
			return Damage;

		return Math::Max(Damage * 0.1, Damage + Math::Min(0, HealthAfterDamage - Threshold));
	}

	bool GetbHurtReaction() property
	{
		 if(HurtReactionTime < SMALL_NUMBER)
		 	return false;
		  if(Time::GetGameTimeSince(HurtReactionTime) > HurtReactionDuration)
		  	return false;
		return true;
	}

	bool GetbHeavyHurtReaction() property
	{
		 if(HeavyHurtReactionTime < SMALL_NUMBER)
		 	return false;
		  if(Time::GetGameTimeSince(HeavyHurtReactionTime) > HurtReactionDuration)
		  	return false;
		return true;
	}

	void ResetConescutiveHammerHits()
	{
		NumConsecutiveHammerHits = 0;
		bIsPerformingFinishingHammerBlow = false;
	}
}