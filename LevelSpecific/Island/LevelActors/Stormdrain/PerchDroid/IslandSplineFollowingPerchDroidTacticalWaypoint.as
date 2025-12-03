class AIslandSplineFollowingPerchDroidTacticalWaypoint : AHazeActor
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "PerchDroidTacticalWaypoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);

	UPROPERTY(DefaultComponent)
	UIslandSplineFollowingPerchDroidTacticalWaypointComponent WaypointComp;
#endif	

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	private AHazeActor Holder;

	float CooldownTimestamp = 0;
	
	UPROPERTY(EditAnywhere)
	const float CooldownTime = 5.0;

	bool IsAt(AHazeActor Actor, float PredictionTime = 0.0) const
	{
		if (Actor == nullptr)
			return false;

		if (Actor.ActorLocation.DistSquared(ActorLocation) < Math::Square(100))
			return true;


		if (PredictionTime != 0.0) // Allow checking for overshoot with negative prediction time
		{
			FVector DeltaMove = Actor.GetActorVelocity() * PredictionTime;
			FVector ToSP = ActorLocation - Actor.ActorLocation;
			if (ToSP.DotProduct(DeltaMove) > 0.0)
			{	
				// We're moving towards sp
				FVector PredictedToWaypoint = (ActorLocation - (Actor.ActorLocation + DeltaMove));
				if (PredictedToWaypoint.DotProduct(DeltaMove) < 0.0)	
				{
					// We will pass waypoint during predicted time
					return true;
				}
			}
		}

		return false;
	}

	bool IsValidHolder(AHazeActor Actor)
	{
		if (UBasicAIHealthComponent::Get(Actor).IsDead())
			return false;
		return true;
	}

	bool IsWithinRange(AHazeActor Actor, float MaxDistance = 5000.0)
	{
		if (!ActorLocation.IsWithinDist(Actor.ActorLocation, MaxDistance))
			return false; // Too far away
		return true;
	}

	// Checks sightline between Waypoint and Target.
	// Should add view offset if not used in an open environment.
	bool HasTargetSightline(AHazeActor IgnoreActor, AHazeActor Target, TArray<AHazeActor> AdditionalIgnoreActors)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(IgnoreActor);
		Trace.IgnoreActor(Target);
		Trace.IgnoreActors(AdditionalIgnoreActors);

		FHitResult Obstruction = Trace.QueryTraceSingle(ActorLocation, Target.ActorCenterLocation);
		return !Obstruction.bBlockingHit;
	}
	
	bool HasOwnerSightline(AHazeActor Actor, AHazeActor Target, TArray<AHazeActor> IgnoreActors)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(Actor);
		Trace.IgnoreActor(Target);
		Trace.IgnoreActors(IgnoreActors);

		FHitResult Obstruction = Trace.QueryTraceSingle(ActorLocation, Actor.ActorCenterLocation);
		return !Obstruction.bBlockingHit;
	}

	bool Hold(AHazeActor Actor)
	{
		if (!IsValidHolder(Actor))
			return false;
		if (Holder == Actor)
			return true;
		SetActorTickEnabled(true);
		Holder = Actor;
		return true;
	}

	bool IsHeldBy(AHazeActor Actor)
	{
		return Holder == Actor;
	}


	bool IsAvailable(AHazeActor Inquirer)
	{
		if (Inquirer == Holder) // just for you, dear Holder
			return true;
		return (Holder == nullptr && CooldownTimestamp < Time::GameTimeSeconds);
	}

	void Release()
	{
		Holder = nullptr;
		SetCooldown();
	}
		
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Holder == nullptr)
			return;

		// Check if we're still being held
		if (!IsValidHolder(Holder))
		{
			SetCooldown();
		}
#if EDITOR
		//Holders[i].bHazeEditorOnlyDebugBool = true;
		if (Holder != nullptr && Holder.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugCircle(ActorLocation, 100, 12, FLinearColor::Blue, 10.0);
		}
#endif

		if (Holder == nullptr)
			SetActorTickEnabled(false);
	}

	void SetCooldown()
	{
		CooldownTimestamp = Time::GameTimeSeconds + CooldownTime;
	}

}