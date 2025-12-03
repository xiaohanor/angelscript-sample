class UPrisonGuardBotZapAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	URemoteHackingPlayerComponent HackerComp;
	UPrisonGuardBotSettings Settings;
	AAIPrisonGuardBotZapper Zapper;

	float DamageTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UPrisonGuardBotSettings::GetSettings(Owner);
		Zapper = Cast<AAIPrisonGuardBotZapper>(Owner);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.ZapAttackRange))
			return false;

		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) 
			return false;

		// Only start attack against players when in front and in camera direction
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player == nullptr)
			return false;
		FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
		if (ViewYawDir.DotProduct(-ToTarget) < 0.707)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.ZapAttackGentlemanCost))
			return false;
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(PlayerTarget))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		GentCostComp.ClaimToken(this, Settings.ZapAttackGentlemanCost);
		HackerComp = URemoteHackingPlayerComponent::Get(Game::Mio);

		AnimComp.RequestFeature(PrisonZapperAnimTags::Shooting, EBasicBehaviourPriority::Medium, this);
		DamageTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, Settings.ExplodeTokenCooldown);
		if (Cooldown.IsOver())
			Cooldown.Set(Settings.ZapAttackCooldown * 0.5); // Attack was interrupted
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Settings.ZapAttackDuration)
		{
			Cooldown.Set(Settings.ZapAttackCooldown);
			return;
		}

		FVector TargetLoc = PlayerTarget.ActorCenterLocation;
		UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(PlayerTarget);
		if ((Mesh != nullptr) && Mesh.DoesSocketExist(n"Hips"))
			TargetLoc = Mesh.GetSocketLocation(n"Hips");
		Zapper.ShootingTargetLocation = TargetLoc;

		if (ActiveDuration > DamageTime)
		{
			float Damage = PlayerTarget.IsMio() ? Settings.ZapAttackMioDamage : Settings.ZapAttackZoeDamage;
			FVector DamageDir = (PlayerTarget.ActorLocation - Zapper.ActorLocation).GetSafeNormal();
			PlayerTarget.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(DamageDir), Zapper.PlayerDamageEffect, Zapper.PlayerDeathEffect);
			if (HackerComp.CurrentHackingResponseComp != nullptr)
			{
				// Deal slight damage to any bot player target is controlling
				UBasicAIHealthComponent HackedHealthComp = UBasicAIHealthComponent::Get(HackerComp.CurrentHackingResponseComp.Owner);
				if (HackedHealthComp != nullptr)
					HackedHealthComp.TakeDamage(0.01, EDamageType::Projectile, Owner);
			}

			FPrisonGuardBotShootParams ShootParams;
			ShootParams.TargetLoc = TargetLoc;
			UPrisonGuardBotEffectHandler::Trigger_OnShoot(Owner, ShootParams);
			DamageTime += Settings.ZapAttackDamageInterval;
		}
	}
}

