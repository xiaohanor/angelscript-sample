class AMeltdownScreenWalkPerchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateTranslate;
	default RotateTranslate.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateTranslate)
	UFauxPhysicsWeightComponent Weight;

	UPROPERTY(DefaultComponent, Attach = Weight)
	UStaticMeshComponent PerchMesh;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};