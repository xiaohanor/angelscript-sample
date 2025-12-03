class AMeltdownScreenWalkCirclePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsSplineFollowComponent RootSplineFollow;
	default RootSplineFollow.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};