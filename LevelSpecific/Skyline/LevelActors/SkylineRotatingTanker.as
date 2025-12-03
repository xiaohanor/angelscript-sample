class ASkylineRotatingTanker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};