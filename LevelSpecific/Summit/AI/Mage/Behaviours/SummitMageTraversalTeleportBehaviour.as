
class USummitMageTraversalTeleportBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AAISummitMage Mage;
	UTeleportTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	USummitMageSettings MageSettings;

	bool bTraversing;
	FVector TargetLocation;
	ATraversalAreaActor TargetArea;
	bool bFoundTargetLocation;

	bool bTeleportStarted;
	bool bTeleportCompleted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UTeleportTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		MageSettings = USummitMageSettings::GetSettings(Owner);
		Mage = Cast<AAISummitMage>(Owner);
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
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		if(TraversalComp.CurrentArea == Area)
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
		if (ActiveDuration > MageSettings.TeleportTelegraphDuration + MageSettings.TeleportDuration + MageSettings.TeleportCompletedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTraversing = false;
		bTeleportStarted = false;
		bTeleportCompleted = false;
		
		if (!HasControl())
			return;

		bFoundTargetLocation = SetTargetLocation();
		if(!bFoundTargetLocation)
		{
			Cooldown.Set(5.0);
			return;
		}

		USummitMageEffectEventHandler::Trigger_TeleportTelegraphStart(Owner, FSummitMageEventTeleportParams(Mage.TeleportIndicator));
		Mage.ShowTeleportIndicator(TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Mage.HideTeleportIndicator();
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bTeleportStarted && ActiveDuration > MageSettings.TeleportTelegraphDuration)
		{
			bTeleportStarted = true;
			USummitMageEffectEventHandler::Trigger_TeleportStart(Owner, FSummitMageEventTeleportParams(Mage.TeleportIndicator));
			Owner.AddActorVisualsBlock(this);
			Owner.AddActorCollisionBlock(this);
		}

		if(!bTeleportCompleted && ActiveDuration > MageSettings.TeleportTelegraphDuration + MageSettings.TeleportDuration)
		{			
			bTeleportCompleted = true;
			Owner.SetActorLocation(TargetLocation);
			TraversalComp.SetCurrentArea(TargetArea);
			USummitMageEffectEventHandler::Trigger_TeleportCompleted(Owner, FSummitMageEventTeleportParams(Mage.TeleportIndicator));
			Owner.RemoveActorVisualsBlock(this);
			Owner.RemoveActorCollisionBlock(this);
			Mage.HideTeleportIndicator();
		}
	}

	private bool SetTargetLocation()
	{
		FVector TargetLoc = TargetComp.Target.ActorLocation;

		// TODO: Use proper pathfinding to determine which area we should traverse to
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		float BestDistSqr = BIG_NUMBER;
		UTraversalScenepointComponent TargetPoint = nullptr;
		UTraversalScenepointComponent BadPoint = nullptr;
		FVector BadDestination;
		float BestBadDistSqr = BIG_NUMBER;

		TargetArea = GetPlayerArea();
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Point : TraversalPoints)
		{
			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				// Transit areas and points where we have to pass beyond the target 
				// will only be considered if there are no better points.
				FVector DestLoc = Point.GetDestination(iDest);
				FVector DestToTarget = TargetLoc - DestLoc;
				float DistSqr = DestToTarget.SizeSquared();
				bool bGoodPoint = (DestToTarget.DotProduct(ToTarget) > 0.0);
				// if (bGoodPoint)
				{
					ATraversalAreaActor DestArea = Cast<ATraversalAreaActor>(Point.GetDestinationArea(iDest));
					if ((DestArea == nullptr) || DestArea.bTransitArea)
						bGoodPoint = false;
					if(DestArea == TraversalComp.CurrentArea)
						continue;
				}
				if (bGoodPoint)
				{
					// Good destination!
					if (DistSqr < BestDistSqr)
					{
						TargetPoint = Point;
						TargetLocation = DestLoc;
						BestDistSqr = DistSqr;	
					}
				}
				else if (DistSqr < Math::Min(BestBadDistSqr, BestDistSqr))
				{
					BadPoint = Point;
					BadDestination = DestLoc;
					BestBadDistSqr = DistSqr;
				}
			}
		}
		if (TargetPoint == nullptr)
		{
			TargetPoint = BadPoint;
			TargetLocation = BadDestination;
		}
		if(TargetPoint != nullptr)
		{
			FVector Offset = (TargetArea.GetActorLocation() - TargetLocation) * 0.1;
			Offset.Z = 0;
			TargetLocation += Offset.GetClampedToMaxSize(300);
			return true;
		}
		return false;
	}	
}