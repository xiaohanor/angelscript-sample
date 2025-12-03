class ULightBeamReactionSettings : UHazeComposableSettings
{
	UPROPERTY()
	float StunDuration = 1.0;
};

class ULightBeamReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	ULightBeamReactionSettings LightBeamReactionSettings;
	UBasicAIHealthComponent HealthComp;

	float StunTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		auto BeamedComp = ULightBeamResponseComponent::Get(Owner);
		if(BeamedComp != nullptr)
		{
			BeamedComp.OnFullyCharged.AddUFunction(this, n"BeamHitBegin");
			BeamedComp.OnChargeReset.AddUFunction(this, n"BeamHitEnd");
		}

		HealthComp = UBasicAIHealthComponent::Get(Owner);

		LightBeamReactionSettings = ULightBeamReactionSettings::GetSettings(Owner);

		Owner.BlockCapabilities(SanctuaryAICapabilityTags::DarkProjectileCollision, this);
	}

	UFUNCTION()
	private void BeamHitBegin()
	{
		if (HealthComp.IsDead())
			return;

		StunTime = BIG_NUMBER;	
	}

	UFUNCTION()
	private void BeamHitEnd()
	{
		if (!HealthComp.IsDead())
			StunTime = Time::GameTimeSeconds + LightBeamReactionSettings.StunDuration;
		else
			StunTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())		
			return false;

		if (Time::GameTimeSeconds > StunTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())		
			return true;

		if (Time::GameTimeSeconds > StunTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.SetStunned();
		Owner.UnblockCapabilities(SanctuaryAICapabilityTags::DarkProjectileCollision, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Owner.BlockCapabilities(SanctuaryAICapabilityTags::DarkProjectileCollision, this);
		HealthComp.ClearStunned();
		if (ActiveDuration > 1.0)
			TargetComp.SetTarget(nullptr); // Select a new target
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::LightBeamReaction, EBasicBehaviourPriority::High, this);
	}
}