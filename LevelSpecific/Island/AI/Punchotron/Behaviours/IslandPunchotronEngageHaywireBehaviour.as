// Move towards attack position
class UIslandPunchotronEngageHaywireBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(BasicAITags::Attack);

	UIslandPunchotronSettings Settings;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UPathfollowingSettings PathingSettings;

	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::HaywireAttack)
			return false;
		if (PanelComp.bIsOnPanel)
			return false;
		//if (AttackComp.bIsAttacking)
		//	return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class)) // check global cooldown
			return false;		
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.HaywireEngageMaxRange))
		 	return false;
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (!Pathfinding::FindNavmeshLocation(TargetComp.Target.ActorLocation, 10.0, 200.0, NavmeshLocation))
				return false;

			if (!Pathfinding::StraightPathExists(Owner.ActorLocation, NavmeshLocation))
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHasStartedTelegraphing = false;
		bHasStartedJets = false;

		Punchotron.AttackDecalComp.Hide();
		Punchotron.AttackDecalComp.Reset();
		Punchotron.AttackTargetDecalComp.Hide();
		Punchotron.AttackTargetDecalComp.Reset();

		AttackComp.bIsAttacking = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
		Punchotron.AttackDecalComp.FadeOut();
		Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);
		Punchotron.AttackTargetDecalComp.FadeOut(0.5);
		Punchotron.AttackTargetDecalComp.DetachFromParent(true);
	}

	FVector CurrentDestinationLocation;
	bool bHasStartedTelegraphing = false;
	bool bHasStartedJets = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// When AttackDecal (search light decal) is close to target, switch to AttackTargetDecalComp (target locked decal)
		if (Punchotron.AttackDecalComp.WorldLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.HaywireEngageMinRange))
		{
			Punchotron.AttackDecalComp.FadeOut();
			Punchotron.AttackTargetDecalComp.FadeIn(0.5);
			Punchotron.AttackTargetDecalComp.DetachFromParent(true);
			Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);
		}

		// Telegraphing and search light
		if (ActiveDuration < Settings. HaywireEngageTelegraphDuration)
		{
			if (!bHasStartedTelegraphing && Owner.ActorForwardVector.DotProduct( (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D()) > 0)
			{
				UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Owner, FIslandPunchotronHaywireAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target, Punchotron.AttackDecalComp));
				UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Game::Mio, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
				UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Game::Zoe, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
				Punchotron.AttackDecalComp.FadeIn();
				bHasStartedTelegraphing = true;				
			}
			Punchotron.AttackDecalComp.LerpWorldLocationTo(TargetComp.Target.ActorLocation, DeltaTime, Settings. HaywireEngageTelegraphDuration * 0.5);			

			DestinationComp.RotateTowards(TargetComp.Target);			
			return;
		}
		// Stop the telegraphing and start jets
		else if (!bHasStartedJets)
		{
			UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
			UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Game::Mio, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Game::Zoe, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
			bHasStartedJets = true;
		}
		// Stop when caught up to decal
		else if (Owner.ActorLocation.IsWithinDist(CurrentDestinationLocation, Settings.HaywireEngageMinRange))
		{
			
			Cooldown.Set(Settings.HaywireEngageMinRangeCooldown);
			UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
			UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
			return;
		}

		// Keep moving towards decals
		FVector CurrentTargetLocation = Punchotron.AttackTargetDecalComp.WorldLocation;
		CurrentDestinationLocation = CurrentTargetLocation;
		//float DestinationOffset = Math::Min(CurrentTargetLocation.Dist2D(Owner.ActorLocation), 300.0); // Distance from target to stop movement		
		//CurrentDestinationLocation = CurrentTargetLocation + (Owner.ActorLocation - CurrentTargetLocation).GetSafeNormal2D() * DestinationOffset;

		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (Pathfinding::FindNavmeshLocation(CurrentDestinationLocation, 10, 500, NavmeshLocation))
				CurrentDestinationLocation = NavmeshLocation;
		}
		else
		{
			FVector GroundLocation;
			if (IslandPunchotron::GetGroundLocation(CurrentDestinationLocation, 500, GroundLocation))
				CurrentDestinationLocation = GroundLocation;
		}

		DestinationComp.MoveTowards(CurrentDestinationLocation, Settings.HaywireEngageMoveSpeed);
	}
}
