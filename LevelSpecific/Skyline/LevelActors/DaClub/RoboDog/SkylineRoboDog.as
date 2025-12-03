class ASkylineRoboDog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	ASkylineHitSlingThing Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Target != nullptr)
		{
			Debug::DrawDebugLine(ActorLocation, Target.ActorLocation, FLinearColor::Yellow, 5.0, 0.0);	
			
			FVector ToTarget = Target.ActorLocation - ActorLocation;
			SetActorRotation(ToTarget.VectorPlaneProject(FVector::UpVector).ToOrientationQuat());
		}
	}

	UFUNCTION()
	void HandleBallStuck(ASkylineHitSlingThing Ball)
	{
		Debug::DrawDebugLine(ActorLocation, Ball.ActorLocation, FLinearColor::Green, 10.0, 5.0);
	}
};