
// Move towards player's flank
class UIslandShieldotronFlankingBehaviour : UBasicBehaviour
{
	// This will only affect movement acceleration on control side. 
	// Any resulting movement will be separately replicated.
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);	

	default CapabilityTags.Add(n"Flanking");
	
	FVector TargetLocation;
	float Range;
	bool bIsRightSide = true;

	const FName RightFlankingToken = n"IslandShieldotronRightFlankingToken";
	const FName LeftFlankingToken = n"IslandShieldotronLeftFlankingToken";
	FName MyFlankingToken;

	FVector InitialForwardDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.GetGentlemanComponent().IsTokenAvailable(LeftFlankingToken) && !TargetComp.GetGentlemanComponent().IsTokenAvailable(RightFlankingToken))
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
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CrowdEncircleMaxRange))
			return true;
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, BasicSettings.CrowdEncircleDeactivationRange))
			return true;
		if(TargetComp.Target.GetActorForwardVector().DotProduct(InitialForwardDir) < 0)
			return true;
		return false;		
	}


	bool bIsRightDir = false;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Range = BasicSettings.CrowdEncircleRange + Math::RandRange(0, BasicSettings.CrowdEncircleRangeVariable);
		
		FVector RightTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorRightVector * Range;
		FVector LeftTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorRightVector * Range * -1.0;
		
		// Check for closest flank point.
		float RightDist = (RightTargetLoc).DistSquared(Owner.ActorLocation);
		float LeftDist = (LeftTargetLoc).DistSquared(Owner.ActorLocation);
		
		UGentlemanComponent GentlemanComp = TargetComp.GetGentlemanComponent();
		bIsRightDir = RightDist < LeftDist;
		if (bIsRightDir && TargetComp.GetGentlemanComponent().IsTokenAvailable(RightFlankingToken))
			MyFlankingToken = RightFlankingToken;
		else
			MyFlankingToken = LeftFlankingToken;

		GentlemanComp.SetMaxAllowedClaimants(MyFlankingToken, 1);

		GentlemanComp.ClaimToken(MyFlankingToken, this);

		InitialForwardDir = TargetComp.Target.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.GetGentlemanComponent().ReleaseToken(MyFlankingToken, this, 10.0);
		Cooldown.Set(3.0);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;		
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		
		
		
		if (bIsRightDir)
		{
			FVector RightTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorRightVector * Range;
			TargetLocation = RightTargetLoc;
		}
		else
		{
			FVector LeftTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorRightVector * Range * -1.0;
			TargetLocation = LeftTargetLoc;
		}
		

		Debug::DrawDebugSphere(TargetLocation);
		Debug::DrawDebugLine(TargetLocation, TargetComp.Target.ActorLocation);
		Debug::DrawDebugLine(TargetLocation, Owner.ActorLocation, LineColor = FLinearColor::Blue);

		// This kind of short range movement with a constantly updating target location, like circle strafing etc 
		// should not detour around obstacles but instead check that there is room to maneuver.		
		// TODO: Check that there is navmesh room to maneuver in wanted direction and back off or stand still instead if not.		
		DestinationComp.MoveTowards(TargetLocation, 600);
	}
}

