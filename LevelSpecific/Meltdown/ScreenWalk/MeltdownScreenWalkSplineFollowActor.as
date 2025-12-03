class AMeltdownScreenWalkSplineFollowActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsSplineFollowComponent RootSplineFollow;
	default RootSplineFollow.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	bool bVisualResponseToJumpTrigger = true;
	UPROPERTY(EditAnywhere)
	float JumpTriggerForce = 500.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

};