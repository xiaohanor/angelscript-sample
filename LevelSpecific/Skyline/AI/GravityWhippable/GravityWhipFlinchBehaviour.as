class UGravityWhipFlinchBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableSettings WhippableSettings;
	UGravityWhippableComponent WhippableComp;

	float Duration;
	bool bFlinch;
	int FlinchCountdown;
	AHazeActor Instigator;

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
	}

	UFUNCTION()
	private void OnThrowHit(FGravityWhipThrowHitData Data)
	{
		bFlinch = true;
		Instigator = Data.Instigator;

		if(IsActive())
		{
			// Wait one tick before requesting flinch again, so that ABP state can restart
			AnimComp.RequestSubFeature(NAME_None, this);
			FlinchCountdown = 1;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bFlinch)
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
		bFlinch = false;
		FlinchCountdown = 0;
		Duration = WhippableSettings.WhipFlinchDuration;
		Owner.ActorRotation = (Instigator.ActorLocation - Owner.ActorLocation).GetSafeNormal2D().Rotation();
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhippable, SubTagAIGravityWhippable::Flinch, EBasicBehaviourPriority::Medium, this, WhippableSettings.WhipFlinchDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Wait one tick before requesting flinch again, so that ABP state can restart
		if(FlinchCountdown > 0)
		{
			FlinchCountdown--;
		}
		else if(bFlinch)
		{
			bFlinch = false;
			Duration = ActiveDuration + WhippableSettings.WhipFlinchDuration;
			AnimComp.RequestSubFeature(SubTagAIGravityWhippable::Flinch, this, WhippableSettings.WhipFlinchDuration);
		}
	}
}