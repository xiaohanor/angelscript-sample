class UIslandZombieDefaultDeathBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAICharacterMovementComponent MoveComp;
	UIslandZombieDeathComponent DeathComp;
	UIslandPushKnockComponent KnockComp;

	float Duration = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DeathComp = UIslandZombieDeathComponent::Get(Owner);
		KnockComp = UIslandPushKnockComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DeathComp.IsDead())
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DeathComp.StartDeath();
		AnimComp.RequestFeature(LocomotionFeatureAITags::Death, SubTagAIDeath::Default, EBasicBehaviourPriority::Maximum, this, Duration);
		Owner.AddMovementImpulse(DeathComp.DeathDirection * 100.0);
		KnockComp.bTriggerImpacts = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DeathComp.CompleteDeath();
		KnockComp.bTriggerImpacts = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.Velocity.Size() < 100.0)
			KnockComp.bTriggerImpacts = false;
	}
}