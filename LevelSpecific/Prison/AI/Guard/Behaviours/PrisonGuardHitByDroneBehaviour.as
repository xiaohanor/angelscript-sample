class UPrisonGuardHitByDroneBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	UPrisonGuardAnimationComponent GuardAnimComp;
	UPrisonGuardComponent GuardComp;
	UPrisonGuardSettings Settings;

	float ExitTime = 0.5;
	float ActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		GuardComp = UPrisonGuardComponent::Get(Owner);
		Settings = UPrisonGuardSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(GuardComp.LastDroneHitTime) > 0.2)
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

	float GetRecoverTime() const property
	{
		return (GuardComp.LastDroneHitTime - ActivationTime) + Settings.HitByDroneStunnedDuration;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated() 
	{
		Super::OnActivated();
		ActivationTime = Time::GameTimeSeconds;
		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stun;
		ExitTime = Math::Max(0.1, GuardAnimComp.AnimInstance.AnimData.StunnedExit.Sequence.ScaledPlayLength - 0.2);	 

		FPrisonGuardDamageParams Params;
		Params.Direction = (Owner.ActorCenterLocation - Game::Mio.ActorLocation).GetSafeNormal();	
		UPrisonGuardEffectHandler::Trigger_OnStunnedStart(Owner, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;
		UPrisonGuardEffectHandler::Trigger_OnStunnedStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < RecoverTime - ExitTime)
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stun;
		else
			GuardAnimComp.Request = EPrisonGuardAnimationRequest::Stop;
	}
}
