UCLASS(HideCategories = "Actor Debug Activation Cooking Tags Physics LOD Collision Rendering Lighting Navigation")
class AIslandJetpackShieldotronTacticalWaypoint : AHazeActor
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "IslandJetpackShieldotronTacticalWaypoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UIslandJetpackShieldotronTacticalWaypointComponent WaypointComp;
#endif	

	

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	private AHazeActor Holder;

	float CooldownTimestamp = 0;

	UPROPERTY(EditAnywhere)
	float Radius = 100.0;

	// Cooldown prevents holding this waypoint after it has been released.
	UPROPERTY(EditAnywhere)
	const float CooldownTime = 5.0;

	bool IsAt(AHazeActor Actor, float AtRadius = 100.0, float PredictionTime = 0.0) const
	{
		if (Actor == nullptr)
			return false;

		if (Actor.ActorLocation.DistSquared(ActorLocation) < Math::Square(AtRadius))
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

	// Should add view offset if not used in an open environment.
	bool HasTargetSightline(AHazeActor Actor, AHazeActor Target, TArray<AHazeActor> IgnoreActors)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(Actor);
		Trace.IgnoreActor(Target);
		Trace.IgnoreActors(IgnoreActors);

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


	bool IsAvailable()
	{
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