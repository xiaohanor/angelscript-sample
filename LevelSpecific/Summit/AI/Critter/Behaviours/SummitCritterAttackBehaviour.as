class USummitCritterAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	AAISummitCritter Critter;
	USummitCritterSettings CritterSettings;

	float AttackTelegraphDuration = 0.5;
	float AttackDuration = 0.25;
	float AttackRecoveryDuration = 0.25;
	float AttackCooldownDuration = 2.0;
	bool bAttacked = false;
	bool bHit = false;

	FVector AttackLocation;
	FVector AttackStartLocation;
	FHazeAcceleratedVector AccAttack;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Critter = Cast<AAISummitCritter>(Owner);
		CritterSettings = USummitCritterSettings::GetSettings(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
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
		if(!GentCostQueueComp.IsNext(this) && (CritterSettings.AttackGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(CritterSettings.AttackGentlemanCost))
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, CritterSettings.AttackGentlemanCost);
		bAttacked = false;
		bHit = false;
		AttackLocation = TargetComp.Target.ActorCenterLocation;
		AttackStartLocation = Critter.ActorLocation;
		Critter.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, CritterSettings.AttackTokenCooldown);
		Critter.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < AttackTelegraphDuration)
			return;

		if(ActiveDuration > AttackTelegraphDuration + AttackDuration)
		{
			AccAttack.Value = Critter.MeshOffsetComponent.WorldLocation;
			AccAttack.AccelerateTo(AttackStartLocation, AttackDuration, DeltaTime);
			Critter.ActorLocation = AccAttack.Value;
			return;
		}

		AccAttack.Value = Critter.ActorLocation;
		AccAttack.AccelerateTo(AttackLocation, AttackDuration, DeltaTime);
		Critter.ActorLocation = AccAttack.Value;

		if(!bHit && Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
		{		
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);	
			if (PlayerTarget != nullptr)
				PlayerTarget.DamagePlayerHealth(0.1);
			bHit = true;
		}
	}
}

