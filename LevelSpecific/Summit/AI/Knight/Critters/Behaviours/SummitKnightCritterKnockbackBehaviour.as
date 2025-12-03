class USummitKnightCritterKnockbackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	bool bKnocked = false;
	FVector KnockDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		auto TailResponseComp = UTeenDragonTailAttackResponseComponent::GetOrCreate(Owner);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}
	
	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		KnockDirection = Params.RollDirection.RotateAngleAxis(90, FVector::UpVector);
		bKnocked = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bKnocked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 0.1)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bKnocked = false;
		AnimComp.RequestFeature(SanctuaryWeeperTags::DeathSquish, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = Owner.ActorLocation + KnockDirection * 100;
		DestinationComp.RotateTowards(TargetLocation);
		DestinationComp.MoveTowards(TargetLocation, 3000);
	}
}

