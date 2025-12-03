
class USummitSmasherTraversalTeleportBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UHazeCharacterSkeletalMeshComponent Mesh;
	UTeleportTraversalComponent TraversalComp;
	USummitSmasherTeleportComponent TeleportComp;
	UBasicAITraversalSettings TraversalSettings;
	USmasherSettings SmasherSettings;

	bool bTraversing;
	FVector StartLocation;
	FVector EndLocation;
	UTraversalScenepointComponent DestComp;

	bool bDigDownCompleted;
	bool bDigAppearStarted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Mesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		TraversalComp = UTeleportTraversalComponent::Get(Owner);
		TeleportComp = USummitSmasherTeleportComponent::GetOrCreate(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		SmasherSettings = USmasherSettings::GetSettings(Owner);
	}

	private ATraversalAreaActor GetPlayerArea() const
	{
		auto PlayerTraversal = UPlayerTraversalComponent::Get(TargetComp.Target);
		if(PlayerTraversal == nullptr)
			return nullptr;
		return PlayerTraversal.AnyArea;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		ATraversalAreaActor Area = GetPlayerArea();
		if(Area == nullptr)
			return false;
		if (TraversalComp.CurrentArea == nullptr || TraversalComp.CurrentArea == Area)
			return false;
		if (TraversalComp.CurrentArea.bTransitArea)
			return true; // Always chase out of a transit area
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > SmasherSettings.DigStartDuration + SmasherSettings.DigDuration + SmasherSettings.DigAppearDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTraversing = false;
		bDigDownCompleted = false;
		bDigAppearStarted = false;		
		DestComp = nullptr;
		
		if (!HasControl())
			return;

		StartLocation = Owner.ActorLocation;

		DestComp = GetDestination();
		if(DestComp == nullptr)
		{
			Cooldown.Set(5.0);
			return;
		}

		TraversalComp.TargetPoint = DestComp;
		DestComp.Use(Owner);

		FVector Direction = (DestComp.Owner.GetActorLocation() - DestComp.GetWorldLocation()).GetSafeNormal();
		Direction.Z = 0;
		EndLocation = DestComp.GetWorldLocation() + Direction * 500.0;

		USmasherEventHandler::Trigger_DigDownStart(Owner, FSmasherEventDigParams(StartLocation, EndLocation));
		AnimComp.RequestFeature(SummitSmasherFeatureTag::Teleport, EBasicBehaviourPriority::Medium, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USmasherEventHandler::Trigger_DigAppearCompleted(Owner, FSmasherEventDigParams(StartLocation, EndLocation));

		TraversalComp.TargetPoint = nullptr;

		if (DestComp != nullptr)
			DestComp.Release(Owner);			

		if(bDigDownCompleted && !bDigAppearStarted)
		{
			Appear(n"AbortDig");
		}

		TeleportComp.TeleportedTime = Time::GetGameTimeSeconds();
		// Mesh.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(!bDigDownCompleted)
		// 	Mesh.AddRelativeRotation(FRotator(0, 0, 1000) * DeltaTime);

		if(!bDigDownCompleted && ActiveDuration > SmasherSettings.DigStartDuration)
		{
			USmasherEventHandler::Trigger_DigDownCompleted(Owner, FSmasherEventDigParams(StartLocation, EndLocation));
			Owner.AddActorVisualsBlock(this);
			Owner.AddActorCollisionBlock(this);
			bDigDownCompleted = true;
		}
		
		if(!bDigAppearStarted && ActiveDuration > SmasherSettings.DigStartDuration + SmasherSettings.DigDuration)
		{
			// Mesh.RelativeRotation = FRotator::ZeroRotator;
			Owner.SetActorLocation(EndLocation);
			Owner.SetActorRotation((TargetComp.Target.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).Rotation());
			TraversalComp.SetCurrentArea(DestComp.Owner);
			Appear(this);			
		}
	}

	private void Appear(FInstigator Instigator)
	{
		Owner.RemoveActorVisualsBlock(this);
		Owner.RemoveActorCollisionBlock(this);
		USmasherEventHandler::Trigger_DigAppearStart(Owner, FSmasherEventDigParams(StartLocation, EndLocation));
		bDigAppearStarted = true;
	}

	private UTraversalScenepointComponent GetDestination()
	{
		FVector TargetLoc = TargetComp.Target.ActorLocation;

		// TODO: Use proper pathfinding to determine which area we should traverse to
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		float BestDistSqr = BIG_NUMBER;
		UTraversalScenepointComponent TargetPoint = nullptr;
		UTraversalScenepointComponent BadPoint = nullptr;
		float BestBadDistSqr = BIG_NUMBER;

		ATraversalAreaActor TargetArea = GetPlayerArea();
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TargetArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Point : TraversalPoints)
		{
			// Transit areas and points where we have to pass beyond the target 
			// will only be considered if there are no better points.
			FVector DestToTarget = TargetLoc - Point.WorldLocation;
			float DistSqr = DestToTarget.SizeSquared();
			bool bGoodPoint = (DestToTarget.DotProduct(ToTarget) > 0.0);
			if (bGoodPoint)
			{
				bGoodPoint = Point.CanUse(Owner);
				ATraversalAreaActor DestArea = Cast<ATraversalAreaActor>(Point.Owner);
				if ((DestArea == nullptr) || DestArea.bTransitArea)
					bGoodPoint = false;
				else if(BehaviourComp.Team != nullptr)
				{
					for(AHazeActor Member: BehaviourComp.Team.GetMembers())
					{
						if (Member == nullptr)
							continue;
						if(Member == Owner)
							continue;
						if(IsCloseToOtherMember(Member, Point))
						{
							bGoodPoint = false;
							break;
						}
					}
				}
			}

			if (bGoodPoint)
			{
				// Good destination!
				if (DistSqr < BestDistSqr)
				{
					TargetPoint = Point;
					BestDistSqr = DistSqr;	
				}
			}
			else if (DistSqr < Math::Min(BestBadDistSqr, BestDistSqr))
			{
				BadPoint = Point;
				BestBadDistSqr = DistSqr;
			}
		}

		if (TargetPoint == nullptr)
			TargetPoint = BadPoint;
		return TargetPoint;
	}

	bool IsCloseToOtherMember(AHazeActor Member, UTraversalScenepointComponent Point)
	{
		if(Member.ActorLocation.IsWithinDist(Point.WorldLocation, SmasherSettings.DigAppearClearRange))
			return true;
		UTeleportTraversalComponent MemberTraversalComp = UTeleportTraversalComponent::GetOrCreate(Member);
		if(MemberTraversalComp == nullptr)
			return false;
		if(MemberTraversalComp.TargetPoint == nullptr) 
			return false;
		if(!MemberTraversalComp.TargetPoint.WorldLocation.IsWithinDist(Point.WorldLocation, SmasherSettings.DigAppearClearRange))
			return false;
		return true;
	}
}