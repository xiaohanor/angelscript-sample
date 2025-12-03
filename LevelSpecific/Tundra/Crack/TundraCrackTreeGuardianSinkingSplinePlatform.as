UCLASS(Abstract)
class ATundraCrackTreeGuardianSinkingSplinePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.RelativeLocation = FVector(-26.862358, 29.638045, 735.0);
	default Mesh.RelativeRotation = FRotator(0.0, -47.812500, 0.0);
	default Mesh.RelativeScale3D = FVector(2.875,Y=13.25,Z=15.0);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedSplineAlpha;

	UPROPERTY(EditAnywhere)
	ATundraRangedLifeGivingActor LifeGiveActorRef;

	UPROPERTY(EditAnywhere)
	bool bVerticalInput = false;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	/* Rise speed expressed in alpha per second. 1 = it will take 1 second to fully rise, 0.5 = it will take 2 seconds to fully rise. */
	// UPROPERTY(EditAnywhere)
	// float MoveSpeed = 0.7;

	/* Sink speed expressed in alpha per second. 1 = it will take 1 second to fully sink, 0.5 = it will take 2 seconds to fully sink. */
	// UPROPERTY(EditAnywhere)
	// float ReturnSpeed = 0.0001;

	/* When the TreeGuardian inputs above this value upwards on the stick the platform will start rising. */
	// UPROPERTY(EditAnywhere)
	// float MinimumInputToRise = 0.25;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SyncedSplineAlpha.Value = -LifeGiveActorRef.LifeReceivingComponent.HorizontalAlpha;
		
		if(bVerticalInput)
			SyncedSplineAlpha.Value = -LifeGiveActorRef.LifeReceivingComponent.VerticalAlpha;

		Mesh.WorldLocation = Spline.Spline.GetWorldLocationAtSplineDistance(SyncedSplineAlpha.Value * Spline.Spline.SplineLength);
	}
}