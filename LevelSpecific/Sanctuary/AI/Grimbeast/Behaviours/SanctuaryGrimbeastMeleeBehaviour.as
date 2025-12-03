class USanctuaryGrimbeastMeleeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIProjectileLauncherComponent ProjectileLauncher;
	USanctuaryGrimbeastSettings Settings;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	float TokenCooldownTime;
	FBasicAIAnimationActionDurations Durations;
	float AttackRadius = 300;

	bool bStartedAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ProjectileLauncher = UBasicAIProjectileLauncherComponent::Get(Owner);
		Settings = USanctuaryGrimbeastSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Durations = FBasicAIAnimationActionDurations();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		if(TokenCooldownTime != 0 && Time::GetGameTimeSince(TokenCooldownTime) > Settings.MeleeTokenCooldown)
		{
			GentCostComp.ReleaseToken(this);
			TokenCooldownTime = 0;
		}
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.MeleeRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.MeleeGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.MeleeGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.MeleeGentlemanCost);
		bStartedAttack = false;

		Durations.Telegraph = Settings.MeleeTelegraphDuration;
		Durations.Anticipation = Settings.MeleeAnticipationDuration;
		Durations.Action = Settings.MeleeAttackDuration;
		Durations.Recovery = Settings.MeleeAttackDuration;
		AnimComp.RequestAction(SanctuaryGrimbeastFeatureTag::Melee, EBasicBehaviourPriority::Low, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.MeleeCooldown);
		TokenCooldownTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			DestinationComp.RotateTowards(TargetComp.Target);
		}

		if(Durations.IsInActionRange(ActiveDuration))
		{		
			FVector AttackLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * 400;
			if(!bStartedAttack)
			{
				bStartedAttack = true;
				USanctuaryGrimbeastEventHandler::Trigger_OnMeleeAttack(Owner, FSanctuaryGrimbeastOnMeleeAttackEventData(AttackLocation));
			}
			
			for(AHazePlayerCharacter Player: Game::Players)
			{
				if(Player.ActorCenterLocation.IsWithinDist(AttackLocation, AttackRadius))
				{
					auto GrimBeast = Cast<AAISanctuaryGrimbeast>(Owner); 
					GrimBeast.LavaComp.SingleApplyLavaHitOnWholeCentipede();
					
					USanctuaryGrimbeastEventHandler::Trigger_OnMeleeAttackHitPlayer(Owner, FSanctuaryGrimbeastOnMeleeAttackHitPlayerEventData(Player));
				}
			}
		}
	}
}