class AMeltdownScreenWalkPullOutActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent Sphere;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};