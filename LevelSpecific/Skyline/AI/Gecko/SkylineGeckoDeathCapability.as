class USkylineGeckoDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Death);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;	
	USkylineGeckoComponent GeckoComp;
	UGravityWhipTargetComponent WhipTarget;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipResponseComponent WhipResponse;
	USkylineGeckoSettings Settings;

	bool bHasPerformedRemotePreDeath = false;
	bool bWasDead = false;
	float DeathDuration;
	float LastCombatGrappleTime = -BIG_NUMBER;
	float LastDeathEffectTime = -BIG_NUMBER;

	TArray<UStaticMeshComponent> HackIndicators;
	UMaterialInterface HackDefaultIndicatorMaterial;
	 
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		WhippableComp.OnImpact.AddUFunction(this, n"OnWhipThrownImpact");

		auto GrappleComp = UGravityBladeCombatTargetComponent::Get(Owner);
		if (GrappleComp != nullptr)
			GrappleComp.OnCombatGrappleActivation.AddUFunction(this, n"OnCombatGrappleStarted");

		TArray<UActorComponent> Comps = Owner.GetComponentsByTag(UStaticMeshComponent, n"HackIndicator");
		for (UActorComponent Comp : Comps)
		{
			HackIndicators.Add(Cast<UStaticMeshComponent>(Comp));
			HackDefaultIndicatorMaterial = HackIndicators.Last().GetMaterial(0);
		}
	}

	UFUNCTION()
	private void OnCombatGrappleStarted()
	{
		LastCombatGrappleTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > DeathDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();

		AnimComp.RequestFeature(FeatureTagGecko::Death, EBasicBehaviourPriority::High, this);

		WhipTarget.Disable(this);

		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		bWasDead = true;
		DeathDuration = Settings.DeathDuration;
		if ((HealthComp.LastAttacker == Game::Zoe) && (HealthComp.LastDamageType == EDamageType::Impact))
			DeathDuration = 0; // Killed by being thrown
		else if (HealthComp.LastAttacker == Game::Zoe)	
			DeathDuration = 0; // Killed by direct hit from something thrown at us
		else if (WhippableComp.bGrabbed && Settings.bCanBeKilledWhenGrabbed)
			DeathDuration = 0.0; // Killed while grabbed
		else if ((HealthComp.LastAttacker == Game::Mio) && (Time::GetGameTimeSince(LastCombatGrappleTime) < 1.0))
			DeathDuration = 0; // Killed while grappled to

		GeckoComp.ApplyWhipGrab(true, EGravityWhipGrabMode::Sling, this);

		GeckoConstrainingPlayer::StopConstraining(GeckoComp);

		if (!bHasPerformedRemotePreDeath)
			USkylineGeckoEffectHandler::Trigger_OnPreDeath(Owner);

		for (UStaticMeshComponent Indicator : HackIndicators)
		{
			Indicator.SetMaterial(0, GeckoComp.HackDyingIndicatorMaterial);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// A bug report shows this effect being started very frequently, so if for some reason this capability 
		// Activate and deactivate every other frame we might get this result.
		// Not sure how this could happen, as the Gecko is disabled and then respawned and should not be in any 
		// position to be killed again immediately, but we'll see if QA can reproduce...
		if (Time::GetGameTimeSince(LastDeathEffectTime) > 1.0)
		{
			LastDeathEffectTime = Time::GameTimeSeconds;	
			USkylineGeckoEffectHandler::Trigger_OnDeath(Owner);
		}

		HealthComp.OnDie.Broadcast(Owner);
		Owner.AddActorDisable(this);
		AnimComp.ClearFeature(this);
		GeckoComp.ClearWhipGrab(this);
		WhippableComp.bThrown = false;
		WhippableComp.bGrabbed = false;
		WhipTarget.Enable(this);

		DamageAIs();
		DamagePlayers();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WhippableComp.bGrabbed && (DeathDuration > 0.0))
		{
			// Extend death explosion indefinitely
			DeathDuration = ActiveDuration + 2.0; 
		}
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasPerformedRemotePreDeath = false;
		Owner.RemoveActorDisable(this);
		if (bWasDead)
			Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		bWasDead = false;

		// Restore indicators
		for (UStaticMeshComponent Indicator : HackIndicators)
		{
			Indicator.SetMaterial(0, HackDefaultIndicatorMaterial);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		bHasPerformedRemotePreDeath = true;
		USkylineGeckoEffectHandler::Trigger_OnPreDeath(Owner);
	}

	UFUNCTION()
	private void OnWhipThrownImpact()
	{
		if (IsActive())
			DeathDuration = 0.0;
	}

	void DamageAIs()
	{
		UHazeTeam Team = HazeTeam::GetTeam(AITeams::Default);
		if (Team == nullptr)
			return;
		for (AHazeActor Target : Team.GetMembers())
		{
			if (Target == nullptr)
				continue;
			if(USkylineGeckoComponent::Get(Target) == nullptr)
				continue;
			if(Target.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.DeathExplosionRadius))
				Damage::AITakeDamage(Target, Settings.DeathExplosionAIDamage, Owner, EDamageType::Explosion);
		}		
	}

	void DamagePlayers()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			if(!Player.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.DeathExplosionRadius))
				continue;
	#if TEST
			if(Player.GetGodMode() == EGodMode::God)
				return;
	#endif
			Player.DealTypedDamage(Owner, Settings.DeathExplosionPlayerDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);

			if (Settings.DeathExplosionPlayerKnockbackForce > 0.0)
			{
				FVector PushDir = (Player.ActorLocation - Owner.ActorLocation).GetNormalizedWithFallback(-Player.ActorForwardVector);
				Player.ApplyStumble(PushDir * Settings.DeathExplosionPlayerKnockbackForce, Settings.DeathExplosionPlayerKnockbackDuration);
			}
		}
	}	
};
