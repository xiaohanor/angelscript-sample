class USkylineGeckoStunnedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USkylineGeckoSettings GeckoSettings;
	bool bRecovering;

	UBasicAIHealthComponent HealthComp;
	USkylineGeckoComponent GeckoComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
	 	USkylineGeckoBlobResponseComponent BlobComp = USkylineGeckoBlobResponseComponent::Get(Owner);
		if (BlobComp != nullptr)
			BlobComp.OnHit.AddUFunction(this, n"OnBlobHit");

		auto ThrowResponseComp = UGravityWhipThrowResponseComponent::Get(Owner);
		if (ThrowResponseComp != nullptr)
			ThrowResponseComp.OnHit.AddUFunction(this, n"OnDebrisHit");

		auto TorDebrisResponseComp = USkylineTorDebrisResponseComponent::Get(Owner);
		if (TorDebrisResponseComp != nullptr)
			TorDebrisResponseComp.OnHit.AddUFunction(this, n"OnTorDebrisHit");
		
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnDebrisHit(FGravityWhipThrowHitData Data)
	{
		OnHitByStuff();
	}

	UFUNCTION()
	private void OnBlobHit()
	{
		OnHitByStuff();
	}

	UFUNCTION()
	private void OnTorDebrisHit(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		OnHitByStuff();
	}

	void OnHitByStuff()
	{
		if(!IsActive())
			HealthComp.SetStunned();

		HealthComp.TakeDamage(GeckoSettings.DebrisDamage, EDamageType::MeleeBlunt, Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!HealthComp.IsStunned())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!HealthComp.IsStunned())
			return true;
		if(ActiveDuration > GeckoSettings.StunnedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		USkylineGeckoEffectHandler::Trigger_OnStunnedStart(Owner);
		GeckoComp.bAllowBladeHits.Apply(true, this, EInstigatePriority::High);
		AnimComp.RequestFeature(FeatureTagGecko::Stunned, SubTagGeckoStunned::Stunned, EBasicBehaviourPriority::High, this);
		bRecovering = false;
		GeckoConstrainingPlayer::StopConstraining(GeckoComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bRecovering && (ActiveDuration > 0.0) && (ActiveDuration > GeckoSettings.StunnedDuration - 1.5))
		{	
			AnimComp.RequestFeature(FeatureTagGecko::Stunned, SubTagGeckoStunned::Recover, EBasicBehaviourPriority::High, this);
			bRecovering = true;
		}
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		USkylineGeckoEffectHandler::Trigger_OnStunnedStop(Owner);
		HealthComp.ClearStunned();
		GeckoComp.bAllowBladeHits.Clear(this);
	}
}