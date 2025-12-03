class ASanctuaryBossMedallionStaticPrototypePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float ArenaRadius = 17000.0;

	UPROPERTY(EditAnywhere)
	bool bShouldSnap = true;

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (AttachParentActor != nullptr)
		{
			FVector Direction = (ActorLocation - AttachParentActor.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		
			if(bShouldSnap)
			{
				SetActorLocation(Direction * ArenaRadius + FVector::UpVector * ActorLocation.Z);
				SetActorRotation(Direction.Rotation());
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};