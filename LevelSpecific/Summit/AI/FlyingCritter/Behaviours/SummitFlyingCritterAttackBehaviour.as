class USummitFlyingCritterAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USummitFlyingCritterSettings CritterSettings;

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
		CritterSettings = USummitFlyingCritterSettings::GetSettings(Owner);
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnReset()
	{
		Owner.RemoveActorCollisionBlock(this);
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
		if(!GentCostQueueComp.IsNext(this))
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
		AttackStartLocation = Owner.ActorLocation;
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		GentCostComp.ReleaseToken(this, CritterSettings.AttackTokenCooldown);
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < AttackTelegraphDuration)
			return;

		if(ActiveDuration > AttackTelegraphDuration + AttackDuration)
		{
			AccAttack.Value = Owner.ActorLocation;
			AccAttack.AccelerateTo(AttackStartLocation, AttackDuration, DeltaTime);
			Owner.ActorLocation = AccAttack.Value;
			return;
		}

		AccAttack.Value = Owner.ActorLocation;
		AccAttack.AccelerateTo(AttackLocation, AttackDuration, DeltaTime);
		Owner.ActorLocation = AccAttack.Value;

		if(!bHit && Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
		{		
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);	
			if (PlayerTarget != nullptr)
				PlayerTarget.DamagePlayerHealth(0.1);
			bHit = true;
		}
	}
}

