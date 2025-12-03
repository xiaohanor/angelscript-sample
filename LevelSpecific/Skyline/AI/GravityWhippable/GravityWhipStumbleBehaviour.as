class UGravityWhipStumbleBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableSettings WhippableSettings;
	UGravityWhippableComponent WhippableComp;

	float Duration = 2.83;
	bool bStumble;
	float PreStumbleTime;
	float PreDeathTime;
	FRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();				
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);

		auto ThrowResponseComp = UGravityWhipThrowResponseComponent::Get(Owner);
		if (ThrowResponseComp != nullptr)
			ThrowResponseComp.OnHit.AddUFunction(this, n"OnThrowHit");

		UHazeActorRespawnableComponent::Get(Owner).OnUnspawn.AddUFunction(this, n"Unspawn");
		
		HealthComp.OnRemotePreDeath.AddUFunction(this, n"WhipImpactRemotePreDeath");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Clean up the remote 
		if(PreDeathTime > SMALL_NUMBER && Time::GetGameTimeSince(PreDeathTime) > 1)
		{
			AnimComp.ClearFeature(this);
			PreDeathTime = 0;
		}
		if(PreStumbleTime > SMALL_NUMBER && Time::GetGameTimeSince(PreStumbleTime) > 1)
		{
			AnimComp.ClearFeature(this);
			PreStumbleTime = 0;
		}
	}

	UFUNCTION()
	private void Unspawn(AHazeActor RespawnableActor)
	{
		bStumble = false;
		PreStumbleTime = 0;
		PreDeathTime = 0;
	}

	UFUNCTION()
	private void WhipImpactRemotePreDeath()
	{
		if(HasControl())
			return;

		if(HealthComp.LastAttacker == Game::Zoe && HealthComp.LastDamageType != EDamageType::MeleeSharp)
		{
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipDeath, EBasicBehaviourPriority::Maximum, this);
			PreDeathTime = Time::GameTimeSeconds;
		}
	}

	UFUNCTION()
	private void OnThrowHit(FGravityWhipThrowHitData HitData)
	{
		if(HealthComp.IsDead())
			return;
		if(IsActive())
			return;
		if(bStumble)
			return;

		bStumble = true;
		Rotation = (Owner.ActorLocation - HitData.Instigator.ActorLocation).GetSafeNormal2D().Rotation();

		if(!HasControl())
		{
			Owner.ActorRotation = Rotation;
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Stumble, EBasicBehaviourPriority::High, this, Duration);
			UEnforcerEffectHandler::Trigger_OnGravityWhipStumble(Owner);
			PreStumbleTime = Time::GameTimeSeconds;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bStumble)
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
		bStumble = false;
		if(Time::GetGameTimeSince(PreStumbleTime) < 1)
			return;
		Owner.ActorRotation = Rotation;
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Stumble, EBasicBehaviourPriority::Medium, this, Duration);
		UEnforcerEffectHandler::Trigger_OnGravityWhipStumble(Owner);
	}
}