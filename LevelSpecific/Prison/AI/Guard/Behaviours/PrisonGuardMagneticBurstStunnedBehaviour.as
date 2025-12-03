class UPrisonGuardMagneticBurstStunnedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	UPrisonGuardAnimationComponent GuardAnimComp;
	UPrisonGuardSettings Settings;

	float RecoverTime = 0.0;
	float ExitTime = 0.5;
	bool bIsRestunned = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		Settings = UPrisonGuardSettings::GetSettings(Owner);
		UMagneticFieldResponseComponent::Get(Owner).OnBurst.AddUFunction(this, n"OnBurst");
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		HealthComp.ClearStunned();
	}

	UFUNCTION()
	private void OnBurst(FMagneticFieldData Data)
	{
		float Damage = GetBurstDamage();
		if (Damage > HealthComp.CurrentHealth - 0.01)
		{
			if (HealthComp.IsStunned() || (Settings.MagneticBurstsToKill < 2))
			{
				// Die when already stunned (or we're allowed to one-shot)
				HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Energy, Game::Zoe);		
				return;
			}
			// Get stunned but don't die
			Damage = HealthComp.CurrentHealth * 0.5; 
		}
		HealthComp.TakeDamage(Damage, EDamageType::Energy, Game::Zoe);
		HealthComp.SetStunned();

		if (IsActive())
		{
			// Prolong any ongoing stun and re-trigger animation
			RecoverTime += Settings.MagneticBurstStunnedDuration;
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Restun;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!HealthComp.IsStunned())
			return false;
		if (HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (HealthComp.IsDead())
			return true;
		if (ActiveDuration > RecoverTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated() 
	{
		Super::OnActivated();

		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stun;
		bIsRestunned = false;	
		RecoverTime = Settings.MagneticBurstStunnedDuration;
		ExitTime = Math::Max(0.1, GuardAnimComp.AnimInstance.AnimData.StunnedExit.Sequence.ScaledPlayLength - 0.2);	 

		FPrisonGuardDamageParams Params;
		Params.Direction = (Owner.ActorCenterLocation - Game::Zoe.ActorLocation).GetSafeNormal();	
		UPrisonGuardEffectHandler::Trigger_OnStunnedStart(Owner, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;
		HealthComp.ClearStunned();

		if (HealthComp.IsAlive())
		{
			// Recover enough health to not get killed by a single burst
			float Damage = GetBurstDamage();
			if (HealthComp.CurrentHealth < Damage)
				HealthComp.SetCurrentHealth(Damage * 1.5);
		}

		UPrisonGuardEffectHandler::Trigger_OnStunnedStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bIsRestunned)
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Restun;
		else if (ActiveDuration < RecoverTime - ExitTime)
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stun;
		else
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;

		bIsRestunned = false; // Stay restunned one tick		
	}

	float GetBurstDamage() const
	{
		return 1.0 / Math::Max(1.0, float(Settings.MagneticBurstsToKill));
	}
}
