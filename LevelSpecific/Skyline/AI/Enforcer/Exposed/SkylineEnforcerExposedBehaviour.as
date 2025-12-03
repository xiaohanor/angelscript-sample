class USkylineEnforcerExposedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UEnforcerDamageComponent DamageComp;
	USkylineEnforcerBodyFieldComponent BodyFieldComp;
	USkylineEnforcerSentencedComponent SentencedComp;

	float Duration;
	bool bExpose;
	AHazeActor Instigator;
	int DamagedCountdown;

	bool bReDamaged;
	float DamagedTime;
	float DamagedDuration = 0.3;
	float ActiveDamage;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();				
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DamageComp = UEnforcerDamageComponent::Get(Owner);
		BodyFieldComp = USkylineEnforcerBodyFieldComponent::Get(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);

		UEnforcerRocketLauncherResponseComponent RocketLauncherResponseComp = UEnforcerRocketLauncherResponseComponent::GetOrCreate(Owner);
		if (RocketLauncherResponseComp != nullptr)
			RocketLauncherResponseComp.OnHit.AddUFunction(this, n"OnRocketHit");

		USkylineTorHammerResponseComponent HammerResponse = USkylineTorHammerResponseComponent::GetOrCreate(Owner);
		if (HammerResponse != nullptr)
			HammerResponse.OnHit.AddUFunction(this, n"OnHammerHit");

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnDamaged");
		DamageComp.bInvulnerable.Apply(true, this);

		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"Respawned");
	}

	UFUNCTION()
	private void Respawned()
	{
		DamageComp.bInvulnerable.Apply(true, this);
		BodyFieldComp.Enable(this);	
	}

	UFUNCTION()
	private void OnDamaged(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                       EDamageType DamageType)
	{
		DamagedTime = Time::GameTimeSeconds;

		if(IsActive())
		{
			// Wait one tick before requesting flinch again, so that ABP state can restart
			AnimComp.RequestSubFeature(NAME_None, this);
			DamagedCountdown = 1;
			bReDamaged = true;

			ActiveDamage += Damage;
			if(ActiveDamage >= HealthComp.MaxHealth / 2)
				DeactivateBehaviour();

			return;
		}

		AnimComp.RequestSubFeature(SubTagAIEnforcerExposed::Damaged, this, DamagedDuration);
	}

	UFUNCTION()
	private void OnRocketHit(float Damage, EDamageType DamageType, AHazeActor RocketInstigator)
	{
		if(HasControl())
			CrumbHit(RocketInstigator);
	}

	UFUNCTION()
	private void OnHammerHit(float Damage, EDamageType DamageType, AHazeActor HammerInstigator)
	{
		if(HasControl())
			CrumbHit(HammerInstigator);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHit(AHazeActor HitInstigator)
	{
		bExpose = true;
		Instigator = HitInstigator;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bExpose)
			return false;
		if(Instigator == nullptr)
			return false;
		if(HealthComp.IsDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		if(HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Duration = 8;
		ActiveDamage = 0;

		DamageComp.bInvulnerable.Apply(false, this);
		bExpose = false;

		DamagedCountdown = 0;
		bReDamaged = false;
		
		Owner.ActorRotation = (Instigator.ActorLocation - Owner.ActorLocation).GetSafeNormal2D().Rotation();
		Instigator = nullptr;

		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::Exposed, SubTagAIEnforcerExposed::Idle, EBasicBehaviourPriority::Medium, this, Duration);
		USkylineEnforcerExposedEffectHandler::Trigger_OnStartExposed(Owner);

		BodyFieldComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if(HealthComp.IsAlive() && !SentencedComp.bSentenced)
		{
			DamageComp.bInvulnerable.Apply(true, this);
			BodyFieldComp.Enable(this);
		}

		USkylineEnforcerExposedEffectHandler::Trigger_OnStopExposed(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleDamaged();

		// Wait one tick before requesting flinch again, so that ABP state can restart
		if(DamagedCountdown > 0)
		{
			DamagedCountdown--;
		}
		else if(bReDamaged)
		{
			bReDamaged = false;
			AnimComp.RequestSubFeature(SubTagAIEnforcerExposed::Damaged, this, DamagedDuration);
		}
	}

	void HandleDamaged()
	{
		if(DamagedTime == 0)
			return;
		if(Time::GetGameTimeSince(DamagedTime) < DamagedDuration)
			return;
		AnimComp.RequestSubFeature(SubTagAIEnforcerExposed::Idle, this, Duration);
		DamagedTime = 0;
	}
}