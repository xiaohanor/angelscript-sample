class AMagnetDroneSpinButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	float SpringStrengthOveride = 1;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagnetSurfaceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UDroneMagneticSocketComponent MagnetSocketComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent CameraComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetSocketComp.OnMagnetDroneAttached.AddUFunction(this, n"MagnetDroneAttach");
		MagnetSocketComp.OnMagnetDroneDetached.AddUFunction(this, n"MagnetDroneAttachEnded");
	}

	UFUNCTION(BlueprintEvent)
	void MagnetDroneAttachEnded(FOnMagnetDroneDetachedParams Params)
	{
		Params.Player.DeactivateCamera(CameraComp,1);
		TranslateComp.SpringStrength = SpringStrengthOveride;
	}

	UFUNCTION(BlueprintEvent)
	void MagnetDroneAttach(FOnMagnetDroneAttachedParams Params)
	{
		Params.Player.ActivateCamera(CameraComp,0.2, this);
		TranslateComp.SpringStrength = 1;
		TranslateComp.ApplyImpulse(Params.Player.GetActorLocation(),(Params.Player.ActorForwardVector + Params.Player.ActorRightVector) * 10);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Print(""+TranslateComp.Velocity,0);
	}
}