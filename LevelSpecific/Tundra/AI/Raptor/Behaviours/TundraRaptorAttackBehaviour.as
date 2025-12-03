class UTundraRaptorAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UTundraRaptorSettings RaptorSettings;

	float AttackTelegraphDuration = 0.5;
	float AttackDuration = 0.25;
	float AttackRecoveryDuration = 0.25;
	float AttackCooldownDuration = 2.0;
	float DamageRadius = 100;
	bool bAttacked = false;
	bool bHit = false;

	FVector AttackLocation;
	FVector AttackStartLocation;
	FHazeAcceleratedVector AccAttack;

	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RaptorSettings = UTundraRaptorSettings::GetSettings(Owner);
		auto Respawn = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		Respawn.OnRespawn.AddUFunction(this, n"OnReset");
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			DamageRadius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION()
	private void OnReset()
	{
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
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
		bAttacked = false;
		bHit = false;
		AttackStartLocation = Owner.ActorLocation;
		Owner.AddActorCollisionBlock(this);
		AnimComp.RequestFeature(FeatureTagStinger::Charge, SubTagStingerCharge::ChargeTelegraph, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AttackLocation = TargetComp.Target.ActorCenterLocation;

		if(ActiveDuration < AttackTelegraphDuration)
			return;

		if(ActiveDuration > AttackTelegraphDuration + AttackDuration)
		{
			AnimComp.RequestFeature(FeatureTagStinger::Charge, SubTagStingerCharge::ChargeEnd, EBasicBehaviourPriority::Medium, this);
			AccAttack.Value = Owner.ActorLocation;
			AccAttack.AccelerateTo(AttackStartLocation, AttackDuration, DeltaTime);
			Owner.ActorLocation = AccAttack.Value;
			return;
		}

		AnimComp.RequestFeature(FeatureTagStinger::Charge, SubTagStingerCharge::Charge, EBasicBehaviourPriority::Medium, this);
		AccAttack.Value = Owner.ActorLocation;
		AccAttack.AccelerateTo(AttackLocation, AttackDuration, DeltaTime);
		Owner.ActorLocation = AccAttack.Value;

		if(!bHit && Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, DamageRadius))
		{		
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);	
			if (PlayerTarget != nullptr)
				PlayerTarget.DamagePlayerHealth(1.0);
			bHit = true;
		}
	}
}

