class ASkylineSwimmingRingForce : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent ForceArea;
	default ForceArea.CapsuleHalfHeight = 200.0;
	default ForceArea.CapsuleRadius = 50.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	FVector DownardsForce = -FVector::UpVector * 100.0;
};