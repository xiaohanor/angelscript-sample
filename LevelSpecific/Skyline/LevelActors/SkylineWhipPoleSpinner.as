class USkylineWhipPoleSpinnerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineWhipPoleSpinnerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto WhipPoleSpinner = Cast<ASkylineWhipPoleSpinner>(Component.Owner);

		DrawArc(WhipPoleSpinner.ActorLocation, WhipPoleSpinner.Angle, 1000.0, WhipPoleSpinner.ActorRightVector, FLinearColor::Green, 10.0, WhipPoleSpinner.ActorUpVector, 24, 300.0);
	}
}

class USkylineWhipPoleSpinnerVisualizerComponent : UActorComponent
{

}

class ASkylineWhipPoleSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent)
	USkylineWhipPoleResponseComponent WhipPoleResponseComponent;

	UPROPERTY(DefaultComponent)
	USkylineWhipPoleSpinnerVisualizerComponent VisualizerComponent;

	TArray<ASkylineWhipPole> AttachedPoles;

	UPROPERTY(EditAnywhere)
	float Angle = 90.0;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 20.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipPoleResponseComponent.OnPoleImpact.AddUFunction(this, n"HandlePoleImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		RotationPivot.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0));

		TArray<ASkylineWhipPole> WhipPoles = AttachedPoles;
		for (auto WhipPole : WhipPoles)
		{
			FVector DirectionFromCenter = (WhipPole.ActorLocation - ActorLocation).VectorPlaneProject(ActorUpVector).SafeNormal;
			WhipPole.ImpactNormal = DirectionFromCenter;

			if (DirectionFromCenter.GetAngleDegreesTo(ActorRightVector) > Angle)
			{
				AttachedPoles.Remove(WhipPole);
				WhipPole.PoleFallOff();
			}
		}
	}

	UFUNCTION()
	private void HandlePoleImpact(FVector Location, FVector Normal, ASkylineWhipPole WhipPole)
	{
		AttachedPoles.Add(WhipPole);

		// WhipPole.PerchPointComp.bShouldValidateWorldUp = false;
		// WhipPole.PerchPointComp.MaximumVerticalJumpToAngle = 90;
	}
};