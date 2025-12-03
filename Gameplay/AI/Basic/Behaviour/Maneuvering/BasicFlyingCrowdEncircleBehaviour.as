
// Shy away from other Ais
class UBasicFlyingCrowdEncircleBehaviour : UBasicBehaviour
{
	// This will only affect movement acceleration on control side. 
	// Any resulting movement will be separately replicated.
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);	

	default CapabilityTags.Add(n"CrowdEncircle");

	int CurrentTeamIndex = 0.0;
	UHazeMovementComponent MoveComp;

	FVector TargetLocation;
	float Range;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CurrentTeamIndex = Math::RandRange(0, 10);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		TArray<AHazeActor> PotentialAvoiders = BehaviourComp.Team.GetMembers();
		if(PotentialAvoiders.Num() < 2)
			return false;
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CrowdEncircleMaxRange))
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, BasicSettings.CrowdEncircleActivationRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		TArray<AHazeActor> PotentialAvoiders = BehaviourComp.Team.GetMembers();
		if(PotentialAvoiders.Num() < 2)
			return true;
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CrowdEncircleMaxRange))
			return true;
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, BasicSettings.CrowdEncircleDeactivationRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Range = BasicSettings.CrowdEncircleRange + Math::RandRange(0, BasicSettings.CrowdEncircleRangeVariable);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!TargetComp.HasValidTarget())
			return;
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CrowdEncircleMaxRange))
			return;

		// Check if some team members are close enough for avoidance consideration
		// Only check one member each tick
		TArray<AHazeActor> ActorsToAvoid = BehaviourComp.Team.GetMembers();

		// Check all confirmed to be close enough for consideration
		FVector OwnLoc = Owner.ActorLocation;
		FVector LocationDir = FVector::ZeroVector;
		for (int i = ActorsToAvoid.Num() - 1; i >= 0; i--)
		{
			ABasicAICharacter Avoidee = Cast<ABasicAICharacter>(ActorsToAvoid[i]);
			if(Avoidee.TargetingComponent.Target != TargetComp.Target)
				continue;
			if(Avoidee == Owner)
				continue;
			FVector AvoidLoc = Avoidee.ActorLocation;
			FVector Dir = (OwnLoc - AvoidLoc).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
			LocationDir += Dir;
		}
		
		LocationDir = LocationDir.GetSafeNormal();
		TargetLocation = TargetComp.Target.ActorLocation + LocationDir * Range;
		TargetLocation.Z += BasicSettings.FlyingCrowdEncircleHeight;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Debug::DrawDebugSphere(TargetLocation);
		// Debug::DrawDebugLine(TargetLocation, TargetComp.Target.ActorLocation);
		// Debug::DrawDebugLine(TargetLocation, Owner.ActorLocation, LineColor = FLinearColor::Blue);
		DestinationComp.MoveTowards(TargetLocation, BasicSettings.CrowdEncircleSpeed);
	}
}

