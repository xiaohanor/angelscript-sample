class UIslandZombieLaunchDeathBehaviour : UBasicBehaviour
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
		KnockComp = UIslandPushKnockComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		DeathComp = UIslandZombieDeathComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DeathComp.IsDead())
			return false;
		if(DeathComp.DeathType != EIslandZombieDeathType::Pushing)
			return false;
		if(Math::RandRange(0,1) == 1)
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
		FVector Dir = DeathComp.DeathDirection;
		Dir.Z = 1.0;
		Owner.AddMovementImpulse(Dir * Math::RandRange(700.0, 1000.0));
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
		if(MoveComp.Velocity.Size() < 50.0 && ActiveDuration > 0.1)
			KnockComp.bTriggerImpacts = false;
	}
}