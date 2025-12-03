event void OnMagnetDroneAttached();

UCLASS(Abstract)
class APrisonDrones_RotatingBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetablesRoot;

	UPROPERTY(DefaultComponent, Attach = TargetablesRoot)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UDroneMagneticZoneComponent MagneticZoneComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	AHazePlayerCharacter MagnetDronePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this,n"MagnetDroneAttached");
	}

	UPROPERTY()
	OnMagnetDroneAttached EventMagnetDroneAttached;

	UFUNCTION()
	private void MagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		FauxRotateComp.ApplyImpulse(Params.Location,Params.Normal*-100);
		EventMagnetDroneAttached.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (IsValid(MagnetDronePlayer))
			FauxRotateComp.ApplyForce(MagnetDronePlayer.GetActorLocation(),  FVector::RightVector * -12);
	}



};
