event void FMaxSecurityFloorGateOpenedEvent();

UCLASS(Abstract)
class AMaxSecurityFloorGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent LeftGateRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent RightGateRoot;

	UPROPERTY(DefaultComponent, Attach = LeftGateRoot)
	UStaticMeshComponent LeftGateMesh;

	UPROPERTY(DefaultComponent, Attach = RightGateRoot)
	UStaticMeshComponent RightGateMesh;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;
	default MagneticFieldComp.bMagnetized = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY()
	FMaxSecurityFloorGateOpenedEvent OnOpened;

	bool bOpened = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticFieldComp.OnStartBeingMagneticallyAffected.AddUFunction(this, n"Magnetized");
	}

	UFUNCTION()
	private void Magnetized()
	{
		if (bOpened)
			return;

		MagneticFieldComp.SetMagnetizedStatus(false);

		bOpened = true;
		OnOpened.Broadcast();
		UMaxSecurityFloorGateEffectEventHandler::Trigger_Opening(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bOpened)
		{
			LeftGateRoot.ApplyAngularForce(10.0);
			RightGateRoot.ApplyAngularForce(-10.0);
		}
	}
}