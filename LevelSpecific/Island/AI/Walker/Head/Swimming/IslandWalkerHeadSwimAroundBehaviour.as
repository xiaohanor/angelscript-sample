class UIslandWalkerHeadSwimAroundBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeMovementComponent MoveComp;
	UIslandWalkerHeadComponent HeadComp;
	AIslandWalkerArenaLimits Arena;
	AIslandWalkerSwimmingBounds Bounds;
	UIslandWalkerSettings Settings;
	AIslandWalkerHeadStumpTarget Stump;
	UIslandWalkerSwimmingObstacleSetComponent ObstacleSet;

	FVector Destination;
	FVector DestinationDirection;
	FSplinePosition BoundsPos;

	float CrossTime;

	float StuckDuration;
	FVector StuckLocation;
	bool bStartMove = true;

	const float ObstacleProbeDistance = 600.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UHazeMovementComponent::Get(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Bounds = TListedActors<AIslandWalkerSwimmingBounds>().GetSingle();
		Settings = UIslandWalkerSettings::GetSettings(Owner);

		if (ensure(Owner.Level.LevelScriptActor != nullptr))
			ObstacleSet = UIslandWalkerSwimmingObstacleSetComponent::GetOrCreate(Owner.Level.LevelScriptActor);

		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if ((Arena == nullptr) || (Bounds == nullptr))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		BoundsPos = Bounds.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation + Owner.ActorForwardVector * 500.0);
		CrossTime = -SMALL_NUMBER;

		bStartMove = true;
		Destination = GetStartDestination();
		DestinationDirection = (Destination - Owner.ActorLocation).GetSafeNormal();	
		CrossTime = ActiveDuration + Math::RandRange(5.0, 10.0);
		ResetStuck();
		
		UIslandWalkerSettings::SetHeadTurnDuration(Owner, Settings.SwimAroundTurnDuration, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
		Stump.AllowDamage();
		HeadComp.bFinDeployed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasReachedDestination())
			UpdateSubmergedDestination();

		// Move towards destination with turn radius
		DestinationComp.RotateTowards(Destination);
		FVector MoveLoc = Owner.ActorLocation + Owner.ActorForwardVector * 100.0;
		float SwimDepth = Settings.SwimAroundDepth;
		if (Owner.ActorLocation.Z > Arena.FloodedPoolSurfaceHeight)
		{
			// Above surface
			if (IsObstructed(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector * ObstacleProbeDistance) ||
				(bStartMove && !Owner.ActorLocation.IsWithinDist2D(Destination, 800.0)))
			{
				// Move above obstacles until near destination and unobstructed
				float Height = Math::GetMappedRangeValueClamped(FVector2D(1200.0, 400.0), FVector2D(Settings.FireBreachingHeight, 600.0), Owner.ActorLocation.Dist2D(Destination));
				MoveLoc.Z = Arena.FloodedPoolSurfaceHeight + Height;
			}
			else
			{
				// Move sharply down
				MoveLoc.Z -= 200.0;
			}
		}
		else if (Owner.ActorLocation.Z > Arena.Height)
		{
			// At normal depth, move while diving under obstacles
			if (IsObstructed(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector * ObstacleProbeDistance))
				SwimDepth = Settings.SwimAroundObstructedDepth;
			MoveLoc = Arena.GetAtFloodedPoolDepth(MoveLoc, SwimDepth); 
			if (Owner.ActorLocation.Z > MoveLoc.Z + 20.0)
				MoveLoc.Z -= 600.0; // Move more downwards when above target depth
		}
		else
		{
			// In the murky depths of the deep central pool, move straight upwards
			MoveLoc = Arena.GetAtFloodedPoolDepth(Owner.ActorLocation, SwimDepth); 
		}

		// Move!
		DestinationComp.MoveTowardsIgnorePathfinding(MoveLoc, Settings.SwimAroundSpeed);

		// When we detect getting stuck we cross to other side of pool
		if (Owner.ActorLocation.IsWithinDist(StuckLocation, 80.0))
			StuckDuration += DeltaTime;
		else
			ResetStuck();
		if (StuckDuration > 0.5)
		{
			CrossTime = 0.0;
			UpdateSubmergedDestination();
		}

		// Can't hurt us when submerged
		if (!Stump.bIgnoreDamage && Arena.GetFloodedSubmergedDepth(Owner) > 300.0)
			Stump.IgnoreDamage();

		// Deploy shark fin when near surface
		if (!HeadComp.bFinDeployed && (Arena.GetFloodedSubmergedDepth(Owner) > -400.0))
			HeadComp.bFinDeployed = true;

#if EDITOR
		// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, MoveLoc, FLinearColor::Yellow, 5.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Destination, FLinearColor::Purple, 4.0);
			Debug::DrawDebugLine(Destination, Destination + FVector(0.0, 0.0, 600.0), FLinearColor::Purple, 4.0);
			Debug::DrawDebugLine(Destination, BoundsPos.WorldLocation, FLinearColor::DPink, 3.0);
			Debug::DrawDebugLine(BoundsPos.WorldLocation, BoundsPos.WorldLocation + FVector(0.0, 0.0, 600.0), FLinearColor::DPink, 3.0);
			FLinearColor FwdColor = FLinearColor::LucBlue;
			FVector Curloc = Owner.ActorLocation;
			FVector FwdLoc = Curloc + Owner.ActorForwardVector * ObstacleProbeDistance;
			for (UIslandWalkerSwimmingObstacleComponent Obstacle : ObstacleSet.Obstacles)
			{
				FLinearColor Color = FLinearColor::Green;
				if (Obstacle.IsObstructing(Curloc, FwdLoc))
					FwdColor = Color = FLinearColor::Red;	
				Obstacle.DebugDraw(Color, 10.0);
			}
			Debug::DrawDebugLine(Curloc, FwdLoc, FwdColor, 10.0);
		}
#endif		
	}

	bool HasReachedDestination()
	{
		if (Owner.ActorLocation.IsWithinDist(Destination, 400.0))
			return true;
		if (DestinationDirection.DotProduct(Destination - Owner.ActorLocation) < 0.0)
			return true; // We've passed destination without coming close, due to turn radius
		return false;
	}

	FVector GetStartDestination()
	{
		// Start by diving down at nearest unobstructed spot ahead of us if possible
		FVector FwdDest = Owner.ActorLocation + Owner.ActorForwardVector * 800.0;

		if (FindClosestUnobstructedLocation(FwdDest, FwdDest + Owner.ActorForwardVector * 2000.0, FwdDest))
			return Arena.GetAtFloodedPoolDepth(FwdDest, Settings.SwimAroundDepth);

		// Try to dive down near center of pool
		FVector CenterDest = Arena.ActorLocation;
		for (int i = 0; i < 3; i++)
		{
			FVector Test = Arena.ActorLocation + Math::GetRandomPointInCircle_XY() * 1200.0;
			FVector TowardsTest = (Test - (Test - Owner.ActorLocation).GetSafeNormal2D() * 400.0);
			if (IsObstructed(Test, TowardsTest))
				continue;
			// Found an unobstructed location near center to submerge at.
			CenterDest = Test;
			break;		
		}
		CenterDest = Arena.GetAtFloodedPoolDepth(CenterDest, Settings.SwimAroundDepth);
		return CenterDest;
	}

	void UpdateSubmergedDestination()
	{
		bStartMove = false;
		if (ActiveDuration > CrossTime)
		{
			BoundsPos.Move(Bounds.Spline.SplineLength * Math::RandRange(0.2, 0.8));	
			CrossTime = ActiveDuration + Math::RandRange(5.0, 10.0);
			ResetStuck();
		}
		else
		{
			// Keep moving along bounds spline in the direction we're currently looking
			if (BoundsPos.WorldForwardVector.DotProduct(Owner.ActorForwardVector) > 0.0)
				BoundsPos.Move(1000.0);
			else 
				BoundsPos.Move(-1000.0);
		}

		Destination = BoundsPos.WorldLocation; 
		Destination += BoundsPos.WorldRightVector * 400.0;
		if (!Owner.ActorLocation.IsWithinDist(Destination, 600.0))
		{
			float BoundsFraction = Math::RandRange(0.7, 1.0);
			Destination = Owner.ActorLocation * (1.0 - BoundsFraction) + BoundsPos.WorldLocation * BoundsFraction;
		}
		Destination = Arena.GetAtFloodedPoolDepth(Destination, Settings.SwimAroundDepth);

		DestinationDirection = (Destination - Owner.ActorLocation).GetSafeNormal();		
	}

	bool FindClosestUnobstructedLocation(FVector Start, FVector End, FVector& ClosestLoc)
	{
		if (ObstacleSet == nullptr)
		{
			ClosestLoc = Start;
			return true;
		}
		FVector Direction = (End - Start).GetSafeNormal2D();
		float Near = BIG_NUMBER;
		float Far = 0.0;
		for (UIslandWalkerSwimmingObstacleComponent Obstacle : ObstacleSet.Obstacles)
		{
			FVector FirstIntersect; 
			FVector SecondIntersect;
			if (!Obstacle.FindIntersections(Start, End, FirstIntersect, SecondIntersect))
				continue;	
			if (Start.IsWithinDist2D(FirstIntersect, Near))
				Near = Start.Dist2D(FirstIntersect);
			if (!Start.IsWithinDist2D(SecondIntersect, Far))
				Far = Start.Dist2D(SecondIntersect);
			if (!Obstacle.bCanFlyOver)
				Far = BIG_NUMBER; // We can only hope for space before this obstacle
		}
		if (Near > 600.0)
		{
			// Space enough before obstacles
			ClosestLoc = Start;
			return true;
		}
		else if ((Far > 0.0) && (Far + 600.0 < Start.Dist2D(End)))
		{
			// Space beyond obstacles
			ClosestLoc = Start + Direction * (Far + 200.0);
			return true;
		}

		// Completely obstructed
		return false;
	}

	bool IsObstructed(FVector Start, FVector End)
	{
		if (ObstacleSet == nullptr)
			return false;
		for (UIslandWalkerSwimmingObstacleComponent Obstacle : ObstacleSet.Obstacles)
		{
			if (Obstacle.IsObstructing(Start, End))
				return true;	
		}
		return false;
	}

	void ResetStuck()
	{
		StuckDuration = 0.0;
		StuckLocation = Owner.ActorLocation;
	}
}