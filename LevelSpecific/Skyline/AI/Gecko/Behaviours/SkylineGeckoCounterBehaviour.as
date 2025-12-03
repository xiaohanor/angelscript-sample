class USkylineGeckoCounterBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAICharacterMovementComponent MoveComp;
	USkylineGeckoSettings GeckoSettings;
	float HitTime;
	FVector CounterLocation;
	FVector ForwardVector;

	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		CounterLocation = Owner.ActorLocation + PlayerTarget.ViewRotation.ForwardVector.ConstrainToPlane(Owner.ActorUpVector) * GeckoSettings.CounterDistance;
		auto HazeCharacter = Cast<AHazeCharacter>(Owner);
		HazeCharacter.CapsuleComponent.IgnoreActorWhenMoving(PlayerTarget, true);
		ForwardVector = (Owner.ActorLocation - CounterLocation).GetSafeNormal();
		AnimComp.RequestFeature(FeatureTagGecko::Dodge, EBasicBehaviourPriority::Medium, this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		auto HazeCharacter = Cast<AHazeCharacter>(Owner);
		HazeCharacter.CapsuleComponent.IgnoreActorWhenMoving(PlayerTarget, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		DestinationComp.RotateTowards(PlayerTarget.ActorLocation);
		float SpeedFactor = Math::Clamp(Owner.ActorLocation.Distance(CounterLocation) / 100, 0.1, 1);
		DestinationComp.MoveTowardsIgnorePathfinding(CounterLocation, GeckoSettings.CounterMoveSpeed * SpeedFactor);
		
		if(DoEnd())
			DeactivateBehaviour();
	}

	private bool DoEnd()
	{
		if(Owner.ActorLocation.IsWithinDist(CounterLocation, 25))
			return true;
		float Dot = ForwardVector.DotProduct((CounterLocation - Owner.ActorLocation).GetSafeNormal());
		if(Dot > 0)
			return true;
		if(DestinationComp.MoveFailed())
			return true;
		if(ActiveDuration > GeckoSettings.CounterMaxDuration)
			return true;
		if(MoveComp.HasWallContact())
			return true;

		return false;
	}
}