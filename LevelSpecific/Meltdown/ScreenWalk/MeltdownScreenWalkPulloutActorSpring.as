class AMeltdownScreenWalkPulloutActorSpring : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsSpringConstraint Spring;

	UPROPERTY(DefaultComponent, Attach = Spring)
	UStaticMeshComponent Sphere;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};