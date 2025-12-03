class AMeltdownScreenWalkReversePolarityActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsWeightComponent Weight;

	UPROPERTY(DefaultComponent, Attach = Weight)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};