
class USummitStoneBeastCritterEncircleBehaviour : UBasicBehaviour
{
	// This will only affect movement acceleration on control side. 
	// Any resulting movement will be separately replicated.
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);	

	default CapabilityTags.Add(n"CrowdEncircle");

	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitStoneBeastCritterSettings Settings;

	private FVector TargetLocation;
	private float Range;

	FName InnerTeamName = n"SummitStoneBeastCritterEncircleInnerTeam";
	FName OuterTeamName = n"SummitStoneBeastCritterEncircleOuterTeam";
	FName CurrentTeamName;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		UHazeTeam InnerTeam  = HazeTeam::GetTeam(InnerTeamName);
		UHazeTeam OuterTeam  = HazeTeam::GetTeam(OuterTeamName);

		if (InnerTeam == nullptr)
		{
			Owner.JoinTeam(InnerTeamName);
			return;
		}
		else if (OuterTeam == nullptr)
		{
			Owner.JoinTeam(OuterTeamName);
			return;
		}

		Owner.LeaveTeam(InnerTeamName);
		Owner.LeaveTeam(OuterTeamName);

		if (InnerTeam.GetMembers().Num() < OuterTeam.GetMembers().Num() * 2)
		{
			Owner.JoinTeam(InnerTeamName);
			CurrentTeamName = InnerTeamName;
		}
		else
		{
			Owner.JoinTeam(OuterTeamName);
			CurrentTeamName = OuterTeamName;
		}
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
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CrowdEncircleMaxRange))
			return false;
		// if(Owner.ActorLocation.IsWithinDist(TargetLocation, Settings.CrowdEncircleActivationRange))
		//  	return false;
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
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CrowdEncircleMaxRange))
			return true;
		if(Owner.ActorLocation.IsWithinDist(TargetLocation, Settings.CrowdEncircleDeactivationRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Range = Settings.CrowdEncircleRange + Math::RandRange(0, Settings.CrowdEncircleRangeVariable);
		if (CurrentTeamName == OuterTeamName)
			Range += 100;
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
			{
				// Check max distance to fellow member targeting opposite player
				if (!Member.ActorLocation.IsWithinDist(Owner.ActorLocation, 300))
					continue;
			}
			
			// Check max distance between target and fellow member
			if (!Member.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, 1000))
				continue;
			
			//Debug::DrawDebugSphere(TargetComp.Target.ActorLocation, 500, Duration = 0.1);

			Members.Add(Member);
		}
		return Members;
	}

	FVector RandomLocalOffset;
	float RandomLocalOffsetTimer = 0;
	float UpdateTargetLocationTimer = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{				
		//Debug::DrawDebugSphere(TargetLocation, 10);
		//Debug::DrawDebugLine(TargetLocation, TargetComp.Target.ActorLocation);
		//Debug::DrawDebugLine(TargetLocation, Owner.ActorLocation, LineColor = FLinearColor::Blue);
		if(!TargetComp.HasValidTarget())
			return;

		UpdateTargetLocationTimer -= DeltaTime;
		if (UpdateTargetLocationTimer < 0.0)
		{
			UpdateTargetLocationTimer =  1.0 + Math::RandRange(0.0, 0.2);
			// Check if some team members are close enough for avoidance consideration.
			TArray<AHazeActor> ActorsToAvoid = GetAvoidMembers();

			// Check all confirmed to be close enough for consideration
			FVector OwnLoc = Owner.ActorLocation;
			FVector AvoidDir = FVector::ZeroVector;
			float ClosestDist = 100;
			for (int i = ActorsToAvoid.Num() - 1; i >= 0; i--)
			{
				AHazeActor Avoidee = ActorsToAvoid[i];
				FVector AvoidLoc = Avoidee.ActorLocation;
				FVector FromAvoidee = (OwnLoc - AvoidLoc).ConstrainToPlane(Owner.ActorUpVector); // can be normalized for a more circle shaped pattern.
				float Dist = FromAvoidee.Size2D();
				AvoidDir += FromAvoidee / (1 + Dist); // Scale contribution linearly by distance
				ClosestDist = Dist < ClosestDist ? Dist : ClosestDist;
			}

			FVector TargetLocAvoidScenepointOffset = FVector::ZeroVector;
			uint NumInfluencingAvoidPoints = 0;
			// Try to stay clear of any avoid points
			TListedActors<ASummitStoneBeastCritterAvoidScenepointActor> AvoidPoints;
			for (ASummitStoneBeastCritterAvoidScenepointActor AvoidPoint : AvoidPoints)
			{			
				float DistToPoint = Owner.ActorLocation.Dist2D(AvoidPoint.ActorLocation);
				float Radius = AvoidPoint.GetScenepoint().Radius;
				if (DistToPoint < Radius) // if within sphere of incluence
				{
					// Move away, scale by dist
					FVector FromPointDir = (Owner.ActorLocation - AvoidPoint.ActorLocation).ConstrainToPlane(Owner.ActorUpVector);
					float AvoidFactor = 1 * Radius/DistToPoint;
					if (AvoidPoint.bIsForcingInForwardDirectionHemisphere)
					{
						if (FromPointDir.DotProduct(AvoidPoint.ActorForwardVector) < 0)
						{
							AvoidFactor = 1000.0 / DistToPoint;
							//Debug::DrawDebugLine(AvoidPoint.ActorLocation, AvoidPoint.ActorLocation + FromPointDir, FLinearColor::Red, 3.0, 1.0, true);
							//Debug::DrawDebugLine(AvoidPoint.ActorLocation, AvoidPoint.ActorLocation + AvoidPoint.ActorRightVector * 100, FLinearColor::Gray, 3.0, 1.0, true);
							FromPointDir = FromPointDir.MirrorByVector(AvoidPoint.ActorForwardVector);
							//Debug::DrawDebugLine(AvoidPoint.ActorLocation, AvoidPoint.ActorLocation + FromPointDir, FLinearColor::Green, 3.0, 1.0, true);
						}
					}
					AvoidDir += (FromPointDir * AvoidFactor) / (1 + DistToPoint);
				}

				// Find a new target location based on avoid points
				if (DistToPoint < Radius + 100) // if within sphere of incluence
				{
					float Offset = AvoidPoint.GetScenepoint().Radius;
					TargetLocAvoidScenepointOffset += AvoidPoint.ActorForwardVector * Offset;
					NumInfluencingAvoidPoints++;
					//Debug::DrawDebugSphere(AvoidPoint.ActorLocation, 10, 12, FLinearColor::Green);
					//Debug::DrawDebugArrow(AvoidPoint.ActorLocation, AvoidPoint.ActorLocation + AvoidPoint.ActorForwardVector * Offset, 5, FLinearColor::Red);
				}					
			}

			if (NumInfluencingAvoidPoints > 0)
				TargetLocAvoidScenepointOffset /= NumInfluencingAvoidPoints; // Average offset

			AvoidDir = AvoidDir.GetSafeNormal();
			
			// Add some local offset for more active movement
			//RandomLocalOffsetTimer -= DeltaTime;
			//if (RandomLocalOffsetTimer < 0)
			//{
			//	RandomLocalOffsetTimer = 1.5;
			RandomLocalOffset = Math::GetRandomPointInCircle_XY() * ClosestDist;
			//}

			TargetLocation = TargetComp.Target.ActorLocation + TargetLocAvoidScenepointOffset + AvoidDir * Range + RandomLocalOffset;

			// Bit too strict...		
			// for (ASummitStoneBeastCritterAvoidScenepointActor AvoidPoint : AvoidPoints)
			// {
			// 	if (!AvoidPoint.bIsForcingInForwardDirectionHemisphere)
			// 		continue;
			
			// 	float DistToPoint = TargetLocation.Dist2D(AvoidPoint.ActorLocation);
			// 	float Radius = AvoidPoint.GetScenepoint().Radius;			
			// 	if (TargetLocation.Dist2D(AvoidPoint.ActorLocation) < Radius)
			// 	{
			// 		FVector ToTargetLocation = (TargetLocation - AvoidPoint.ActorLocation).GetSafeNormal2D();
			// 		TargetLocation = TargetLocation + AvoidPoint.ActorForwardVector * (1 - DistToPoint/Radius);
			// 	}			
			// }
		}

		float Dist = 1 + TargetLocation.Dist2D(Owner.ActorLocation);
		float ScaleDownRange = 100;
		float SpeedFactor = Math::Min(1.0, Dist / ScaleDownRange);
		
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, Settings.CrowdEncircleSpeed * SpeedFactor);
	}
}