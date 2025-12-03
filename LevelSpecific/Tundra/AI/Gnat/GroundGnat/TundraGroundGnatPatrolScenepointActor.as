event void FTundraGnatPatrolScenepointEvent();

// Any ground gnat spawned or ending an entrance anim/spline within the radius of 
// the scenepoint will patrol this area, never leaving it
class ATundraGroundGnatPatrolScenepointActor : AScenepointActorBase
{
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;
	default ScenepointComponent.Radius = 600.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTundraGroundGnatPatrolComponent PatrolComp;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FTundraGnatPatrolScenepointEvent OnStartPatrolling;

	UPROPERTY()
	FTundraGnatPatrolScenepointEvent OnStopPatrolling;

	private TArray<AHazeActor> Patrollers;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);	
	}

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};

	bool IsAt(AHazeActor Actor, float PredictionTime = 0.0) const
	{
		return ScenepointComponent.IsAt(Actor, PredictionTime);
	}

	bool CanAggro(AHazeActor Actor) const
	{
		if (Actor == nullptr)
			return false;
		if (!IsAt(Actor))
			return false;
		if (PatrolComp.WorldLocation.IsWithinDist(ActorLocation, ScenepointComponent.Radius * PatrolComp.AggroFraction))
			return true;
		return false;
	}

	bool IsValidPatroller(AHazeActor Actor)
	{
		if (!ActorLocation.IsWithinDist(Actor.ActorLocation, GetScenepoint().Radius + 500.0))
			return false; // Too far away
		if (UBasicAIHealthComponent::Get(Actor).IsDead())
			return false; // Weekend at Bernies
		return true;
	}

	bool Patrol(AHazeActor Actor)
	{
		if (!IsValidPatroller(Actor))
			return false;
		if (Patrollers.Contains(Actor))
			return true;
		SetActorTickEnabled(true);
		Patrollers.Add(Actor);
		if (HasControl() && (Patrollers.Num() == 1))
			CrumbStartPatrolling();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Check if we're still being patrolled
		bool bHadPatrollers = (Patrollers.Num() > 0);
		for (int i = Patrollers.Num() - 1; i >= 0; i--)
		{
			if (!IsValidPatroller(Patrollers[i]))
				Patrollers.RemoveAtSwap(i);
		}
		if (HasControl() && bHadPatrollers && (Patrollers.Num() == 0))
			CrumbStopPatrolling();
		if (Patrollers.Num() == 0)
			SetActorTickEnabled(false);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbStartPatrolling()
	{
		OnStartPatrolling.Broadcast();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbStopPatrolling()
	{
		OnStopPatrolling.Broadcast();
	}
}

class UTundraGroundGnatPatrolComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Patrol")
	float AggroFraction = 0.8;
}

#if EDITOR
class UTundraGroundGnatPatrolComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraGroundGnatPatrolComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UTundraGroundGnatPatrolComponent PatrolComp = Cast<UTundraGroundGnatPatrolComponent>(Component);
		if (PatrolComp == nullptr)
			return;
		UScenepointComponent Scenepoint = UScenepointComponent::Get(Component.Owner);
		if (Scenepoint == nullptr)
			return;
		DrawCircle(PatrolComp.WorldLocation, Scenepoint.Radius * PatrolComp.AggroFraction, FLinearColor::Red, 10.0); 	
	}
}
#endif
