class USummitStoneBeastCritterAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	AAISummitStoneBeastCritter Critter;
	USummitStoneBeastCritterSettings Settings;

	float AttackTelegraphDuration = 0.2;
	float AttackDuration = 0.40;
	float AttackRecoveryDuration = 0.35;
	float AttackCooldownDuration = 2.0;
	bool bAttacked = false;
	bool bStartedRecover = false;
	bool bLunged = false;
	bool bHit = false;

	FVector AttackLocation;
	FHazeAcceleratedVector AccAttack;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Critter = Cast<AAISummitStoneBeastCritter>(Owner);
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Critter);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnReset()
	{
		Critter.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (Settings.AttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AttackTelegraphDuration + AttackDuration + AttackRecoveryDuration)
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bAttacked = false;
		bLunged = false;
		bHit = false;
		bStartedRecover = false;
		USummitStoneBeastCritterEffectHandler::Trigger_OnAttackStart(Critter);

		Target = TargetComp.Target;
		AttackLocation = Target.ActorLocation;
		FVector ToAttackLocation = (AttackLocation - Critter.ActorLocation);
		AttackLocation = Critter.ActorLocation + ToAttackLocation.RotateTowards(Critter.ActorRightVector, Math::RandRange(-15,15));
		AttackLocation.Z = Target.ActorLocation.Z;

		//if (UPlayerMovementComponent::Get(TargetComp.Target).IsInAir())
		//	AttackLocation.Z = Target.ActorCenterLocation.Z;

		AnimComp.RequestFeature(FeatureTagCrystalCrawler::Attacks, SummitCrystalCrawlerSubTags::AttackEnter, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		Critter.MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraph
		if(ActiveDuration < AttackTelegraphDuration)
			return;

		// Recover
		if(ActiveDuration > AttackTelegraphDuration + AttackDuration)
		{

			if(!bStartedRecover)
				USummitStoneBeastCritterEffectHandler::Trigger_OnAttackRecover(Critter);
			
			AccAttack.Value = Critter.MeshOffsetComponent.WorldLocation;
		 	AccAttack.AccelerateTo(Critter.ActorLocation, AttackRecoveryDuration, DeltaTime);
		 	Critter.MeshOffsetComponent.WorldLocation = AccAttack.Value;
			bStartedRecover = true;
		 	return;
		}

		// Lunge to target
		AccAttack.Value = Critter.MeshOffsetComponent.WorldLocation;
		AccAttack.AccelerateTo(AttackLocation, AttackDuration, DeltaTime);
		Critter.MeshOffsetComponent.WorldLocation = AccAttack.Value;

		if(!bLunged)
		{
			USummitStoneBeastCritterEffectHandler::Trigger_OnAttackLunge(Critter);
		}

		bLunged = true;

		if(!bHit && Critter.MeshOffsetComponent.WorldLocation.IsWithinDist(Target.ActorCenterLocation, BasicSettings.AttackRange))
		{		
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);	
			if (PlayerTarget != nullptr)
			{
				PlayerTarget.DealTypedDamage(Owner, 0.1, EDamageEffectType::ObjectSharp, EDeathEffectType::ObjectSharp);
				USummitStoneBeastCritterEffectHandler::Trigger_OnHitPlayer(Critter, FOnStoneCritterHitPlayerParams(PlayerTarget));
			}
			bHit = true;
		}
	}
}

