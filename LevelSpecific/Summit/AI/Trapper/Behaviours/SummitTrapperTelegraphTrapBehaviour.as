class USummitTrapperTelegraphTrapBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	AAISummitTrapper SummitTrapper;
	USummitTrapperSettings TrapperSettings;

	UAcidTailBreakableComponent AcidTailBreakComp;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitTrapperTrapComponent TrapComp;

	float TelegraphDuration = 2.0;
	float ProjectileReleaseDuration = 1.0;
	float TelegraphTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SummitTrapper = Cast<AAISummitTrapper>(Owner);
		AcidTailBreakComp = UAcidTailBreakableComponent::Get(Owner);
		TrapperSettings = USummitTrapperSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		TrapComp = USummitTrapperTrapComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
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
		if (AcidTailBreakComp.IsWeakened())
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
		if(!GentCostComp.IsTokenAvailable(TrapperSettings.TrapGentlemanCost))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (Time::GameTimeSeconds > TelegraphTime)
			return true;

		if(!TargetComp.HasValidTarget())
			return true;

		if (AcidTailBreakComp.IsWeakened())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TelegraphTime = Time::GameTimeSeconds + TelegraphDuration;
		GentCostComp.ClaimToken(TrapComp, TrapperSettings.TrapGentlemanCost);
		TrapComp.OnReleasePlayer.AddUFunction(this, n"OnReleasePlayer");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.PendingReleaseToken(TrapComp);
		Cooldown.Set(3);
	}

	UFUNCTION()
	private void OnReleasePlayer()
	{
		GentCostComp.ReleaseToken(TrapComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
	}
} 