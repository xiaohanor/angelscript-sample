// Move towards attack position
class UIslandPunchotronEngageSpinningAttackBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default CapabilityTags.Add(BasicAITags::Attack);

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandPunchotronSettings Settings;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronAttackComponent AttackComp;

	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::SpinningAttack)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class)) // check global cooldown
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		// When in range and straight path exists		
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SpinningAttackMaxRange)
			&& Pathfinding::StraightPathExists(Owner.ActorLocation, TargetComp.Target.ActorLocation) )
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHasStartedTelegraphing = false;
		bHasStartedJets = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);		
	}

	bool bHasStartedTelegraphing = false;
	bool bHasStartedJets = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Settings. HaywireEngageTelegraphDuration)
		{
			// if (!bHasStartedTelegraphing && Owner.ActorForwardVector.DotProduct( (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D()) > 0)
			// {
			// 	UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Owner, FIslandPunchotronHaywireAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			// 	bHasStartedTelegraphing = true;
			// }

			DestinationComp.RotateTowards(TargetComp.Target);			
			return;
		}
		else
		{
			if (!bHasStartedJets)
			{
				UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
				UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
				bHasStartedJets = true;
			}
		}

		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.SpinningAttackEngageMinRange))
		{
			Cooldown.Set(Settings.HaywireEngageMinRangeCooldown);
			UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
			UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, Settings.HaywireEngageMoveSpeed);
	}
}