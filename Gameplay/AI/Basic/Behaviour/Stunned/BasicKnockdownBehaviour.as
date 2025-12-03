
class UBasicKnockdownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIHealthComponent HealthComp;
	UBasicAIKnockdownComponent KnockdownComp; 
	UCapsuleComponent CapsuleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(Owner);
		CapsuleComp = UCapsuleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!HealthComp.ShouldReactToDamage(BasicSettings.KnockdownDamageTypes, 0.5) && !KnockdownComp.HasKnockdown())
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

		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
		KnockdownComp.ConsumeKnockdown();
		HealthComp.SetStunned();

		// Request knockdown
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Knockdown, EBasicBehaviourPriority::High, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
		HealthComp.ClearStunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < BasicSettings.KnockdownDuration - 0.5)
		{
			// Keep requesting knockdown until we are ready to end moving hold
			AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Knockdown, EBasicBehaviourPriority::High, this);
		}

		if (ActiveDuration < BasicSettings.KnockdownDuration)
		{
			TargetComp.SetTarget(nullptr); // Select a new target
			HealthComp.ClearStunned();
			return;
		}
	}
}