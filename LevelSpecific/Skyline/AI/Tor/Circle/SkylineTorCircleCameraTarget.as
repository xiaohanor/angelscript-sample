class ASkylineTorCircleCameraTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(EditInstanceOnly)
	AActor CenterActor;

	FHazeAcceleratedVector AccLoc;
	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Dir = (Game::Zoe.ActorLocation - CenterActor.ActorLocation).GetSafeNormal2D();

		AccLoc.SpringTo(Game::Zoe.ActorLocation - Dir * 250 - FVector::UpVector * 150, 50, 0.75, DeltaSeconds);
		ActorLocation = AccLoc.Value;

		AccRot.SpringTo(Dir.Rotation(), 50, 0.75, DeltaSeconds);
		ActorRotation = AccRot.Value;
	}
}