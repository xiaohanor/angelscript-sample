class APigHouse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StrugglePosition;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams StruggleAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorTickEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Mesh.WorldTransform = Math::TInterpTo(Mesh.WorldTransform, StrugglePosition.WorldTransform, DeltaSeconds, 2);
		if (Mesh.WorldTransform.Location.PointsAreNear(StrugglePosition.WorldLocation, SMALL_NUMBER))
		{
			Mesh.WorldTransform = StrugglePosition.WorldTransform;
			ActorTickEnabled = false;
		}
	}

	UFUNCTION(BlueprintCallable)
	void DestroyHouse()
	{
		ActorTickEnabled = true;
		Mesh.PlaySlotAnimation(StruggleAnim);
	}
};