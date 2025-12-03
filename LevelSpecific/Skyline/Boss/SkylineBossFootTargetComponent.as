class USkylineBossFootTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossFootTargetComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto FootTargetComponent = Cast<USkylineBossFootTargetComponent>(Component);

		if (FootTargetComponent.ActorWithFootTargets == nullptr)
			return;

		USkylineBossFootTargetComponent FootTargetToAttach;

		TArray<USkylineBossFootTargetComponent> FootTargets;
		FootTargetComponent.ActorWithFootTargets.GetComponentsByClass(FootTargets);

		float ClosestDistanceSquared = BIG_NUMBER;
		for (auto FootTarget : FootTargets)
		{
			float DistSquared = FootTargetComponent.WorldLocation.DistSquared(FootTarget.WorldLocation);
			if (DistSquared < ClosestDistanceSquared)
			{
				ClosestDistanceSquared = DistSquared;
				FootTargetToAttach = FootTarget;
			}
		}

		if (FootTargetToAttach == nullptr)
			return;

		DrawDashedLine(FootTargetComponent.WorldLocation, FootTargetToAttach.WorldLocation, FLinearColor::Green, 10.0, 40.0);
	}
}

event void FSkylineBossFootTargetPlacedSignature();
event void FSkylineBossFootTargetLiftedSignature();

UCLASS(Abstract)
class USkylineBossFootTargetComponent : UStaticMeshComponent
{
	default bAbsoluteScale = true;
	default bHiddenInGame = true;

	UPROPERTY(EditInstanceOnly)
	AActor ActorWithFootTargets;

	USkylineBossFootTargetComponent FootTargetToAttach;

	UPROPERTY()
	FSkylineBossFootTargetPlacedSignature OnFootPlaced;
	UPROPERTY()
	FSkylineBossFootTargetLiftedSignature OnFootLifted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorWithFootTargets == nullptr)
			return;

		TArray<USkylineBossFootTargetComponent> FootTargets;
		ActorWithFootTargets.GetComponentsByClass(FootTargets);

		float ClosestDistanceSquared = BIG_NUMBER;
		for (auto FootTarget : FootTargets)
		{
			float DistSquared = WorldLocation.DistSquared(FootTarget.WorldLocation);
			if (DistSquared < ClosestDistanceSquared)
			{
				ClosestDistanceSquared = DistSquared;
				FootTargetToAttach = FootTarget;
			}
		}

		if (FootTargetToAttach == nullptr)
			return;

		FootTargetToAttach.AttachToComponent(this);

		FootTargetToAttach.OnFootPlaced.AddUFunction(this, n"HandleFootPlaced");
		FootTargetToAttach.OnFootLifted.AddUFunction(this, n"HandleFootLifted");

	//	Debug::DrawDebugPoint(WorldLocation, 10.0, FLinearColor::Red);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleFootPlaced()
	{
		OnFootPlaced.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleFootLifted()
	{
		OnFootLifted.Broadcast();
	}
}