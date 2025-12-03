
// Shy away from other Ais
class UBasicCrowdEncircleBehaviour : UBasicBehaviour
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
		TArray<AHazeActor> PotentialAvoiders = GetAvoidMembers();
		if(PotentialAvoiders.Num() == 0)
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
		TArray<AHazeActor> PotentialAvoiders = GetAvoidMembers();
		if(PotentialAvoiders.Num() == 0)
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

	TArray<AHazeActor> GetAvoidMembers() const
	{
		TArray<AHazeActor> AllMembers = BehaviourComp.Team.GetMembers();
		TArray<AHazeActor> Members;
		for(AHazeActor Member: AllMembers)
		{
			if ((Member == Owner) || (Member == nullptr))
				continue;
			UBasicAITargetingComponent OtherTargetComp = UBasicAITargetingComponent::Get(Member);
			if(OtherTargetComp == nullptr || OtherTargetComp.Target != TargetComp.Target)
				continue;
			Members.Add(Member);
		}
		return Members;
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
		TArray<AHazeActor> ActorsToAvoid = GetAvoidMembers();

		// Check all confirmed to be close enough for consideration
		FVector OwnLoc = Owner.ActorLocation;
		FVector LocationDir = FVector::ZeroVector;
		for (int i = ActorsToAvoid.Num() - 1; i >= 0; i--)
		{
			AHazeActor Avoidee = ActorsToAvoid[i];
			FVector AvoidLoc = Avoidee.ActorLocation;
			FVector Dir = (OwnLoc - AvoidLoc).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
			LocationDir += Dir;
		}
		
		LocationDir = LocationDir.GetSafeNormal();
		TargetLocation = TargetComp.Target.ActorLocation + LocationDir * Range;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Debug::DrawDebugSphere(TargetLocation);
		// Debug::DrawDebugLine(TargetLocation, TargetComp.Target.ActorLocation);
		// Debug::DrawDebugLine(TargetLocation, Owner.ActorLocation, LineColor = FLinearColor::Blue);

		// This kind of short range movement with a constantly updating target location, like circle strafing etc 
		// should not detour around obstacles but instead check that there is room to maneuver.		
		// TODO: Check that there is navmesh room to maneuver in wanted direction and back off or stand still instead if not.
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, BasicSettings.CrowdEncircleSpeed);
	}
}

