class ASkylineSubwayWallRun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	UGrappleWallrunPointComponent GrapplePointLeft;
	default GrapplePointLeft.bAllowForward = false;
	default GrapplePointLeft.bAllowBackwards = true;
	default GrapplePointLeft.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default GrapplePointLeft.WidgetVisualOffset = FVector::UpVector * 50.0;

	UPROPERTY(DefaultComponent)
	UGrappleWallrunPointComponent GrapplePointRight;
	default GrapplePointRight.bAllowForward = true;
	default GrapplePointRight.bAllowBackwards = false;
	default GrapplePointRight.RelativeRotation = FRotator(0.0, 180.0, 0.0);
	default GrapplePointRight.WidgetVisualOffset = FVector::UpVector * 50.0;

	UPROPERTY(EditAnywhere)
	float Length = 100.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Pivot.RelativeScale3D = FVector(1.0, Length * 0.01, 1.0);
		GrapplePointLeft.RelativeLocation = FVector::RightVector * (Length * 0.5 - 50.0);
		GrapplePointRight.RelativeLocation = -FVector::RightVector * (Length * 0.5 - 50.0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};