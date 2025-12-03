
class UBasicHurtReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!HealthComp.ShouldReactToDamage(BasicSettings.HurtDamageTypes, 0.5))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!HealthComp.IsStunned())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		HealthComp.SetStunned();

		// Request hurt of suitable type. No mh expected, so single request will do.
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::High, this, BasicSettings.HurtDuration);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.ClearStunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > BasicSettings.HurtDuration)
		{
			AnimComp.Reset();
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}
	}
}