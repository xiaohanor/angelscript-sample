UCLASS(NotBlueprintable)
class UPirateShipObstacleComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	bool bAlwaysRelevant = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bAlwaysRelevant"))
	float Radius = 5000;

	TArray<UPrimitiveComponent> ComponentsToCollideWith;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UPrimitiveComponent> AllPrimitives;
		Owner.GetComponentsByClass(AllPrimitives);

		ComponentsToCollideWith.Empty();
		for(auto Primitive : AllPrimitives)
		{
			if(Primitive.CollisionEnabled == ECollisionEnabled::NoCollision || Primitive.CollisionEnabled == ECollisionEnabled::QueryOnly)
				continue;

			ComponentsToCollideWith.Add(Primitive);
		}

		Pirate::GetObstacleManager().Obstacles.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Pirate::GetObstacleManager().Obstacles.RemoveSingleSwap(this);
	}

	bool IsRelevantFor(FVector InLocation, float InRadius) const
	{
		if(bAlwaysRelevant)
			return true;

		float Distance = WorldLocation.Distance(InLocation);
		return Distance < InRadius + Radius;
	}
};

#if EDITOR
class UPirateShipObstacleComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateShipObstacleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Obstacle = Cast<UPirateShipObstacleComponent>(Component);
		if(Obstacle == nullptr)
			return;

		DrawWireSphere(Obstacle.WorldLocation, Obstacle.Radius, FLinearColor::Red, 3, 12, true);
	}
}
#endif

UCLASS(NotBlueprintable)
class UPirateShipObstacleManager : UObject
{
	TArray<UPirateShipObstacleComponent> Obstacles;
}

namespace Pirate
{
	UPirateShipObstacleManager GetObstacleManager()
	{
		return Game::GetSingleton(UPirateShipObstacleManager);
	}

	TArray<UPirateShipObstacleComponent> GetObstacles()
	{
		return GetObstacleManager().Obstacles;
	}
}