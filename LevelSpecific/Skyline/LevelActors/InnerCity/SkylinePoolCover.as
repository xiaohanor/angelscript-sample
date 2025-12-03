class ASkylinePoolCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent PoolCoverMesh;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};