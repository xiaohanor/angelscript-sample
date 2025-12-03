class UEnforcerChargeMeleeApproachBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineEnforcerSettings Settings;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UEnforcerGrenadeLauncherComponent GrenadeLauncher;
	UEnforcerChargeMeleeComponent MeleeComp;

	float TelegraphDuration = 0.5;
	float AnticipationDuration = 0.3;
	float AttackDuration = 0.3;
	float RecoveryDuration = 0.6;

	TSet<AHazePlayerCharacter> HasHitSet;
	float ProximityTimer = 0;
	bool bStartAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineEnforcerSettings::GetSettings(Owner);		
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeleeComp = UEnforcerChargeMeleeComponent::GetOrCreate(Owner);
		GrenadeLauncher = UEnforcerGrenadeLauncherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.ChargeMeleeAttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.ChargeMeleeAttackGentlemanCost))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (ProximityTimer < Settings.MeleeAttackActivationTimer)
			return false;
		if ((GrenadeLauncher != nullptr) && (GrenadeLauncher.LastLaunchedProjectile != nullptr) && 
			(Time::GetGameTimeSince(GrenadeLauncher.LastLaunchedProjectile.LaunchTime) < 5.0))
			return false; // Best not to walk towards enemies when we've just thrown a grenade their way

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > Settings.ChargeMeleeApproachMaxDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Nearest player serves as target for the attack
		if (Owner.ActorLocation.DistSquared(Game::Mio.ActorLocation) < Owner.ActorLocation.DistSquared(Game::Zoe.ActorLocation) )
			MeleeComp.TargetPlayer = Game::Mio;
		else
			MeleeComp.TargetPlayer = Game::Zoe;

		HasHitSet.Reset();
		GentCostComp.ClaimToken(this, Settings.ChargeMeleeAttackGentlemanCost);

		UEnforcerEffectHandler::Trigger_OnChargeMeleeApproachStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(1.0);
		ProximityTimer = 0;
		AnimComp.ClearFeature(this);
		GentCostComp.ReleaseToken(this);
		UEnforcerEffectHandler::Trigger_OnChargeMeleeApproachStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (!Owner.ActorLocation.IsWithinDist(Game::Mio.ActorLocation, Settings.ChargeMeleeAttackActivationRange) &&
			!Owner.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, Settings.ChargeMeleeAttackActivationRange))
			ProximityTimer = 0;
		else
			ProximityTimer += DeltaTime;

		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(MeleeComp.TargetPlayer.ActorLocation, 200);
		if(Owner.ActorLocation.IsWithinDist(MeleeComp.TargetPlayer.ActorLocation, 150))
			DeactivateBehaviour();
	}
}