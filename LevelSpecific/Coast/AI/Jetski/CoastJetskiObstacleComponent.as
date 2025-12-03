class UCoastJetskiObstacleComponent : USceneComponent
{
	UPROPERTY()
	float Radius = 1000.0;	
}

#if EDITOR
class UCoastJetskiObstacleComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastJetskiObstacleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Obstacle = Cast<UCoastJetskiObstacleComponent>(InComponent);
		if (Obstacle == nullptr)
			return;

		DrawCircle(Obstacle.WorldLocation, Obstacle.Radius * Math::Max(Obstacle.WorldScale.X, Obstacle.WorldScale.Y), FLinearColor::Red, 5.0);
	}
}
#endif