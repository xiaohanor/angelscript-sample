class USummitCrystalEscapeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USummitMeltComponent MeltComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!MeltComp.bMelted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!MeltComp.bMelted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		//AnimComp.RequestFeature(FeatureTagSummitRubyKnight::Melted, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Speed = 500;
		AHazeActor EscapeFrom = Game::Zoe;
		FVector Dir = (Owner.ActorLocation - EscapeFrom.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		DestinationComp.MoveTowards(Owner.ActorLocation + Dir * Speed, Speed);
		DestinationComp.RotateTowards(EscapeFrom.ActorLocation);
	}
}