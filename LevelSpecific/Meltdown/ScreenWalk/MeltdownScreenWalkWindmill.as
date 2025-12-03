class AMeltdownScreenWalkWindmill : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};