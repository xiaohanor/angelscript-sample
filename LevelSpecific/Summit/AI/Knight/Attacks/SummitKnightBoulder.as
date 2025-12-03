event void FKnightBoulderEventSignature();

UCLASS(Abstract)
class ASummitKnightBoulder : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent TelegraphDecal;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;
	default RegisterComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly)
	float Gravity = 982.0 * 4.0;

	UPROPERTY(EditInstanceOnly)
	float DurationToInitialImpact = 0.5;

	UPROPERTY(EditInstanceOnly)
	float BounceSpeed = 1500.0;

	UPROPERTY(EditInstanceOnly)
	float TumbleSpeed = 240.0;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	TArray<FVector> BounceLocations;

	UPROPERTY(EditInstanceOnly)
	bool bFallAtEnd = false;

	UPROPERTY(EditInstanceOnly)
	float MaxDelayFromObstructingWalls = 5.0;

	UPROPERTY(EditInstanceOnly)
	FHazeRange DelayWhenObstructingWallsAreNear;
	default DelayWhenObstructingWallsAreNear.Min = 400.0; 
	default DelayWhenObstructingWallsAreNear.Max = 3000.0; 

#if EDITOR
	UPROPERTY(EditInstanceOnly)
	ASummitKnightArenaActor SplineVisualizeArena;
#endif

	UPROPERTY()
	FKnightBoulderEventSignature OnReachedDestination;

	bool bVisualsAndCollisionDisabled = false;
	FVector Destination;
	float LandHeight;
	int iBounce;
	TArray<UHazeDecalComponent> BounceDecals;
	bool bReachedDestination = false;
	float LaunchTime;
	FVector PrevLoc;
	bool bIsMoving = false;
	bool bIsSettling = false;
	float SettleTimer;

	bool bDelayedLaunch = false;
	float LaunchDelayedTime = BIG_NUMBER;
	
	FVector TumbleAxis;
	FQuat LandingRotation;
	
	TPerPlayer<float> CheckHitDragonTime;
	TMap<UHazeSplineComponent, float> InitialImpactDistanceAlongSplines;
	TArray<AHazeActor> ObstructingWalls;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Land where we are placed in editor (or fall below if we won't land)
		PrevLoc = ActorLocation;
		Destination = ActorLocation;
		if (bFallAtEnd)
			LandHeight = Destination.Z - 10000.0;
		else 
			LandHeight = Destination.Z;
		LandingRotation = Mesh.WorldTransform.Rotation;

		// Remove bounce locations too close together
		for (int i = BounceLocations.Num() - 1; i >= 1; i--)
		{
			if (BounceLocations[i].IsWithinDist(BounceLocations[i - 1], 1.0))
				BounceLocations.RemoveAt(i);
		}

		// Transform bounce locations to world space
		for (int i = 0; i < BounceLocations.Num(); i++)
		{
			BounceLocations[i] = ActorTransform.TransformPosition(BounceLocations[i]);
		}

		// Place decals for all bounce locations except first (which is where boulder spawn)
		TelegraphDecal.DetachFromParent(true);
		if (BounceLocations.Num() > 0)
		{
			BounceDecals.SetNum(BounceLocations.Num() - 1);
			for (int i = 0; i < BounceDecals.Num(); i++)
			{
				UHazeDecalComponent Decal = UHazeDecalComponent::Create(this, FName("BounceDecal_" + (i + 1)));
				Decal.DetachFromParent(true); 
				Decal.WorldTransform = TelegraphDecal.WorldTransform;
				Decal.DecalMaterial = TelegraphDecal.DecalMaterial;
				Decal.DecalColor = TelegraphDecal.DecalColor;
				Decal.AddComponentVisualsBlocker(this);
				BounceDecals[i] = Decal;
			}
		}

		DisableVisualsAndCollision();

		KnightBoulderDevToggles::ShowDamageDetection.MakeVisible();
		KnightBoulderDevToggles::DebugDisplayObstructionsDelays.MakeVisible();
	}

	void DisableVisualsAndCollision()
	{
		if (bVisualsAndCollisionDisabled)
			return;
		bVisualsAndCollisionDisabled = true;
		AddActorVisualsBlock(this);
		AddActorCollisionBlock(this);
	}

	void EnableVisualsAndCollision()
	{
		if (!bVisualsAndCollisionDisabled)
			return;
		bVisualsAndCollisionDisabled = false;
		RemoveActorVisualsBlock(this);
		RemoveActorCollisionBlock(this);
	}

	bool CanLaunch() const
	{
		if (bIsMoving)
			return false; // Can't relaunch while moving
		if (ObstructingWalls.Num() == 0)
			return true;
		if (bDelayedLaunch && (Time::GameTimeSeconds > LaunchDelayedTime + MaxDelayFromObstructingWalls))
			return true; // Launch even though there might be walls in the way
		return false;
	}

	UFUNCTION()
	void Launch()
	{
		// Need to start ticking whether we launch or get delayed
		SetActorTickEnabled(true);

		if (!CanLaunch())
		{
			if (!bIsMoving && !bDelayedLaunch && (ObstructingWalls.Num() > 0))
			{
				// Delay launch due to new obstructions
				bDelayedLaunch = true;
				LaunchDelayedTime = Time::GameTimeSeconds;
			}
			return;
		}

		LaunchTime = Time::GameTimeSeconds;
		bDelayedLaunch = false;
		bIsMoving = true;
		bIsSettling = false;

		if (BounceLocations.Num() == 0)
		{
			// Fall from somewhat arbitrary height
			ActorVelocity = FVector::ZeroVector;
			ActorLocation = Destination + FVector(0.0, 0.0, BounceSpeed * DurationToInitialImpact);
		}
		else
		{
			ActorLocation = BounceLocations[0];
			FVector FirstImpactLoc = GetInitialImpactLocation();
			float Speed = BounceLocations[0].Dist2D(FirstImpactLoc) / DurationToInitialImpact;
			ActorVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(BounceLocations[0], FirstImpactLoc, Gravity, Speed);
			
			// Place decals. Note that first bounce location (spawn location) does not have a decal.
			for (int i = 0; i < BounceDecals.Num(); i++)
			{
				BounceDecals[i].WorldLocation = BounceLocations[i + 1];
				BounceDecals[i].RemoveComponentVisualsBlocker(this);
			}
		}
		PrevLoc = ActorLocation;

		FVector TravelDir = (ActorLocation - Destination).GetSafeNormal();
		TumbleAxis = TravelDir.CrossProduct(FVector::UpVector).GetSafeNormal();
		float TravelDuration = DurationToInitialImpact + GetInitialImpactLocation().Dist2D(Destination) / BounceSpeed;
		Mesh.WorldRotation = (FQuat(TumbleAxis, Math::DegreesToRadians(-TumbleSpeed * TravelDuration)) * LandingRotation).Rotator(); 

		TelegraphDecal.WorldLocation = Destination;
		TelegraphDecal.SetVisibility(true);
		iBounce = 1;	
		bReachedDestination = false;
		EnableVisualsAndCollision();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			CheckHitDragonTime[Player] = 0.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (KnightBoulderDevToggles::DebugDisplayObstructionsDelays.IsEnabled())
			DebugDrawObstructionDelay();	

		if (bDelayedLaunch)
		{
			if (!CanLaunch())
				return;
			Launch();
		}

		PrevLoc = ActorLocation;
		if (!bIsSettling)
		{
			FVector GravityAcceleration = FVector(0.0, 0.0, -Gravity);
			ActorVelocity += GravityAcceleration * DeltaTime;	
			FVector NewLoc = ActorLocation + ActorVelocity * DeltaTime + GravityAcceleration * 0.5 * Math::Square(DeltaTime);

			if (ActorVelocity.Z < 1.0)
			{
				// Falling, check if we've reached next bounce or final destination
				if (BounceLocations.IsValidIndex(iBounce))
				{
					if (NewLoc.Z < BounceLocations[iBounce].Z)
					{
						// Bounce!
						BounceDecals[iBounce - 1].AddComponentVisualsBlocker(this);
						iBounce++;	
						FVector NextLoc = (BounceLocations.IsValidIndex(iBounce)) ? BounceLocations[iBounce] : Destination;
						ActorVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(NewLoc, NextLoc, Gravity, BounceSpeed);
						USummitKnightFallingBoulderEventHandler::Trigger_OnBounce(this);
					}
				}
				else 
				{
					// Falling towards destination
					if (!bReachedDestination && NewLoc.Z < Destination.Z)
					{	
						bReachedDestination = true;	
						TelegraphDecal.SetVisibility(false);
						OnReachedDestination.Broadcast();
					}
					if (NewLoc.Z < LandHeight)
					{
						// We've fallen or bounced to where we shall stop
						bIsMoving = false;
						NewLoc.Z = LandHeight;
						if (bFallAtEnd)
						{
							SetActorTickEnabled(false);
							DisableVisualsAndCollision();	
							USummitKnightFallingBoulderEventHandler::Trigger_OnFallenAway(this);
						}
						else
						{
							bIsSettling = true;
							SettleTimer = 0.3;
							PrevLoc = NewLoc;
							USummitKnightFallingBoulderEventHandler::Trigger_OnLand(this);
						}		
					}		
				}

			}
			SetActorLocation(NewLoc);
		}

		if (bIsMoving || bIsSettling)
			Mesh.WorldRotation = (FQuat(TumbleAxis, Math::DegreesToRadians(TumbleSpeed * DeltaTime)) * Mesh.WorldTransform.Rotation).Rotator();

		if (bIsSettling)
		{
			if (Mesh.WorldTransform.Rotation.Equals(LandingRotation, 0.05) || (SettleTimer < 0.0))
			{
				bIsSettling = false;
				SetActorTickEnabled(false);
			}
			SettleTimer -= DeltaTime;
		}

		if (!ActorVelocity.IsNearlyZero(100.0))
		{
			// Check for player impacts
			float HitRadius = Mesh.BoundsRadius * 0.5;
			FVector ProbeLoc = ActorLocation + ActorVelocity * 0.01;
			float ActiveDuration = Time::GetGameTimeSince(LaunchTime);
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (ActiveDuration < CheckHitDragonTime[Player])
					continue;
				if (!Player.HasControl())
					continue;

				if (!ProbeLoc.IsWithinDist(Player.ActorCenterLocation, HitRadius * 1.5))
					continue;

				// Stumble from near impact at the very least	
				FTeenDragonStumble Stumble;
				float Distance = 600.0;
				Stumble.Duration = 0.5;
				Stumble.Move = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * Distance;
				Stumble.ArcHeight = Distance * 0.25;
				Stumble.Apply(Player);

				// Damage. Note that both stumble and damage is internally networked.
				if (ProbeLoc.IsWithinDist(Player.ActorCenterLocation, HitRadius))
					Player.DamagePlayerHealth(1.0); // Splat! (currently will not likely occur since you'll gte pushed away first)
				else
					Player.DamagePlayerHealth(0.8); // Ouch

				CheckHitDragonTime[Player] = ActiveDuration + 0.5;	
			}

			if (KnightBoulderDevToggles::ShowDamageDetection.IsEnabled())
			{
				Debug::DrawDebugSolidSphere(ProbeLoc, HitRadius, FLinearColor::Red * 0.6);			
				Debug::DrawDebugSphere(ProbeLoc, HitRadius * 1.5, 12, FLinearColor::Yellow);			
			}
		}
	}

	bool IsIntersecting(FVector Start, FVector End, float Radius, float HalfHeight)
	{
		if (bVisualsAndCollisionDisabled)
			return false;

		FVector NearestOwn;
		FVector NearestOther;
		Math::FindNearestPointsOnLineSegments(Start, End, PrevLoc, ActorLocation, NearestOther, NearestOwn);

		// Roughly box shaped, so radius * sqrt(2) will be size at side centers and radius * 1.0 at diagonals
		float BoundsSize = Mesh.BoundsRadius * 0.71;
		if (!NearestOwn.IsWithinDist2D(NearestOther, Radius + BoundsSize))
			return false;

		// We're intersecting top down, check height
		float Top = Math::Max(PrevLoc.Z, ActorLocation.Z) + BoundsSize;
		float Bottom = Math::Min(PrevLoc.Z, ActorLocation.Z) - BoundsSize;
		float OtherTop = Math::Max(Start.Z, End.Z) + HalfHeight;
		float OtherBottom = Math::Min(Start.Z, End.Z) - HalfHeight;
		if (OtherBottom > Top)
			return false;
		if (OtherTop < Bottom)
			return false;
		return true;
	}

	FVector GetInitialImpactLocation() const
	{
		if (HasActorBegunPlay())
		{
			if (BounceLocations.Num() < 2)  
				return Destination;
			return BounceLocations[1];
		}

		// Visualizer preview
		if (BounceLocations.Num() < 2)  
			return ActorLocation; 
		return ActorTransform.TransformPosition(BounceLocations[1]);
	}

	void ReportWallPosition(AHazeActor Wall, FSplinePosition SplinePos)
	{	
		if (!HasActorBegunPlay())
			return;

		if (SplinePos.CurrentSpline == nullptr)
			return;

		if (!InitialImpactDistanceAlongSplines.Contains(SplinePos.CurrentSpline))
		{
			FVector InitialImpact = GetInitialImpactLocation();
			float DistAlongSpline = GetDistanceAlongOrOutsideSpline(SplinePos.CurrentSpline, InitialImpact);
			InitialImpactDistanceAlongSplines.Add(SplinePos.CurrentSpline, DistAlongSpline);
		}

		float DeltaAlongSpline = InitialImpactDistanceAlongSplines[SplinePos.CurrentSpline] - SplinePos.CurrentSplineDistance;
		if (DelayWhenObstructingWallsAreNear.IsInRange(DeltaAlongSpline))
			ObstructingWalls.AddUnique(Wall);
		else
			ObstructingWalls.RemoveSingleSwap(Wall);
	}

	float GetDistanceAlongOrOutsideSpline(UHazeSplineComponent Spline, FVector Location) const
	{
		float DistAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(Location);
		if ((DistAlongSpline < 1.0) || (DistAlongSpline > Spline.SplineLength - 1.0))
		{
			// Before/after spline, adjust distance as if extending further
			FTransform SplineTransform = Spline.GetWorldTransformAtSplineFraction((DistAlongSpline < 1.0) ? 0.0 : 1.0);
			DistAlongSpline += SplineTransform.InverseTransformPosition(Location).X;
		}
		return DistAlongSpline;		
	}

	UFUNCTION(DevFunction)
	void TestLaunch()
	{
		Launch();
	}

	void DebugDrawObstructionDelay() const
	{
		FVector ImpactLoc = GetInitialImpactLocation();
		if (bDelayedLaunch)
			Debug::DrawDebugSphere(ImpactLoc, 200.0, 6, FLinearColor::Red, 10.0);
		FVector Offset = FVector(0.0, 0.0, 500.0);
		for (AHazeActor Obstruction : ObstructingWalls)
		{
			Debug::DrawDebugLine(ImpactLoc, Obstruction.ActorLocation + Offset, FLinearColor::Red, 10.0);
			Debug::DrawDebugCapsule(Obstruction.ActorLocation + Offset, 600.0, 200.0, FRotator::ZeroRotator, FLinearColor::Red, 10.0);
		}
		for (auto Slot : InitialImpactDistanceAlongSplines)
		{
			if ((Slot.Value < 1.0) || (Slot.Value > Slot.Key.SplineLength - 1))
				continue;
			DebugDrawSplineRangeEdge(Slot.Key, Slot.Value - DelayWhenObstructingWallsAreNear.Min, ImpactLoc);
			DebugDrawSplineRangeEdge(Slot.Key, Slot.Value - DelayWhenObstructingWallsAreNear.Max, ImpactLoc);
			break;
		}
	}

	void DebugDrawSplineRangeEdge(UHazeSplineComponent Spline, float DistAlongSpline, FVector ImpactLoc) const
	{
		FTransform RangeEdge = Spline.GetWorldTransformAtSplineDistance(Math::Min(Spline.SplineLength, DistAlongSpline));
		FVector RangeFwd = RangeEdge.Rotation.ForwardVector;
		if (DistAlongSpline < 0.0)
			RangeEdge.Location = RangeEdge.Location + RangeFwd * DistAlongSpline;
		if (DistAlongSpline > Spline.SplineLength)
			RangeEdge.Location = RangeEdge.Location + RangeFwd * (DistAlongSpline - Spline.SplineLength);
		FVector Offset = FVector(0.0, 0.0, 400.0);
		Debug::DrawDebugSolidPlane(RangeEdge.Location + Offset, RangeFwd, 500.0, 500.0, FLinearColor::Yellow * 0.4);	
		Debug::DrawDebugLine(ImpactLoc, RangeEdge.Location + Offset, FLinearColor::Yellow * 0.4, 10.0);	
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (BounceLocations.Num() == 0)
			return;

		// Simulate bounces
		if (BounceLocations.Num() == 1)
		{
			VisualizeTrajectory(BounceLocations[0], FVector::ZeroVector, BounceLocations[0].Size2D() / DurationToInitialImpact);
		}
		else
		{
			VisualizeTrajectory(BounceLocations[0], BounceLocations[1], BounceLocations[0].Dist2D(BounceLocations[1]) / DurationToInitialImpact);
			for (int i = 1; i < BounceLocations.Num() - 1; i++)
			{
				VisualizeTrajectory(BounceLocations[i], BounceLocations[i + 1], BounceSpeed);
			}
			VisualizeTrajectory(BounceLocations.Last(), FVector::ZeroVector, BounceSpeed);
		}

		if (MaxDelayFromObstructingWalls > 0.0)
		{
			FVector ImpactLoc = GetInitialImpactLocation();
			if (SplineVisualizeArena != nullptr)
			{
				float DistAlongSpline = GetDistanceAlongOrOutsideSpline(SplineVisualizeArena.Spline, ImpactLoc);
				DebugDrawSplineRangeEdge(SplineVisualizeArena.Spline, DistAlongSpline - DelayWhenObstructingWallsAreNear.Min, ImpactLoc);
				DebugDrawSplineRangeEdge(SplineVisualizeArena.Spline, DistAlongSpline - DelayWhenObstructingWallsAreNear.Max, ImpactLoc);
			}
			else
			{
				Debug::DrawDebugString(ImpactLoc + FVector(0.0, 0.0, 100.0), "Set spline visualize arena to see where we delay launch when there are walls within that range along spline.", Scale = 2);
			}
		}
	}

	void VisualizeTrajectory(FVector From, FVector To, float Speed) const
	{
		if (From.IsWithinDist(To, 0.1))
			return;
		FVector WorldFrom = ActorTransform.TransformPosition(From);
		FVector WorldTo = ActorTransform.TransformPosition(To);
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(WorldFrom, WorldTo, Gravity, Speed);
		Trajectory::DebugDrawTrajectoryWithDestination(WorldFrom, WorldTo, Velocity, -FVector::UpVector, Gravity, FLinearColor::Black);
	}
#endif
};

UCLASS(Abstract)
class USummitKnightFallingBoulderEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}

	// Triggers when a boulder that will fall forever is hidden
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFallenAway() {}
}

namespace KnightBoulderDevToggles
{
	const FHazeDevToggleBool ShowDamageDetection;
	const FHazeDevToggleBool DebugDisplayObstructionsDelays;
}
