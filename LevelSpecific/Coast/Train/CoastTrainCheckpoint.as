class ACoastTrainCheckpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UCoastTrainCheckpointComponent Dummy;

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeScale3D = FVector(100.0);
	default Billboard.SpriteName = "Anchor";
#endif

	UPROPERTY(Category = Rail, EditInstanceOnly)
	AActor CheckpointRail;

	UPROPERTY(Category = Rail, EditInstanceOnly)
	bool bFlipDirection = false;

	UHazeSplineComponent GetCheckpointSpline() property
	{
		if (CheckpointRail == nullptr)
			return nullptr;

		return UHazeSplineComponent::Get(CheckpointRail);
	}

	FSplinePosition GetCheckpointSplinePosition() property
	{
		auto Spline = CheckpointSpline;
		if (Spline == nullptr)
			return FSplinePosition();

		FSplinePosition Position = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation, false);
		if (bFlipDirection)
			Position.ReverseFacing();
		return Position;
	}
}

class UCoastTrainCheckpointComponent : UActorComponent {}
class UCoastTrainCheckpointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastTrainCheckpointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Checkpoint = Cast<ACoastTrainCheckpoint>(Component.Owner);
		auto Spline = Checkpoint.CheckpointSpline;

		// Uh oh! Error!
		if (Spline == nullptr)
		{
			DrawCross(Checkpoint.ActorLocation);
			return;
		}

		FSplinePosition TargetPosition = Checkpoint.CheckpointSplinePosition;

		// Draw arrow to target
		DrawLine(Checkpoint.ActorLocation, TargetPosition.WorldLocation, FLinearColor::Blue, Thickness = 15.0, bScreenSpace = true);

		// Draw forward vector
		DrawArrow(TargetPosition.WorldLocation, TargetPosition.WorldLocation + TargetPosition.WorldForwardVector * 1000.0, FLinearColor::Red, Thickness = 50.0);
	}

	void DrawCross(FVector Location)
	{
		FVector A = FVector::RightVector * 150.0;
		FVector B = FVector::UpVector * 150.0;

		DrawLine(Location - A - B, Location + A + B, FLinearColor::Red, Thickness = 12.0);
		DrawLine(Location - A + B, Location + A - B, FLinearColor::Red, Thickness = 12.0);
	}
}