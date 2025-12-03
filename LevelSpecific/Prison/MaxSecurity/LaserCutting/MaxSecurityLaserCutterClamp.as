class AMaxSecurityLaserCutterClamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent ClampRoot;
	default ClampRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 14000.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Always controlled on the magnet side, for immediate feedback
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	void ActivateClamp()
	{
		bActive = true;
		ClampRoot.SpringStrength = 4.2;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
#if !RELEASE
			if(DevToggleMaxSecurity::DisableLaserCutterObstacles.IsEnabled())
			{
				ClampRoot.ApplyForce(ClampRoot.WorldLocation - (ClampRoot.RightVector * 400.0), ActorUpVector + ActorRightVector * 5000);
				return;
			}
#endif

			if (!bActive)
			{
				ClampRoot.ApplyForce(ClampRoot.WorldLocation - (ClampRoot.RightVector * 400.0), ClampRoot.UpVector * 2000.0);
			}
		}
	}
}