UCLASS(Abstract)
class AMagnetDronePushable : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UFauxPhysicsTranslateComponent FauxTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	USceneComponent MagnetScene;

	UPROPERTY(DefaultComponent, Attach = MagnetScene)
	UStaticMeshComponent MeshComp;
	default MeshComp.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = MagnetScene)
	UDroneMagneticZoneComponent MagnetZoneComp;

	UPROPERTY(DefaultComponent, Attach = MagnetScene)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UArrowComponent ForceDirection;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDroneMagneticSurfaceComponent MagnetSurfaceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	bool bPush = false;
	bool bHitMax;

	float Strength = 0;
	float SpringStrength = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetSurfaceComp.OnMagnetDroneAttached.AddUFunction(this,n"MagnetDroneAttached");
		MagnetSurfaceComp.OnMagnetDroneDetached.AddUFunction(this,n"MagnetDroneDetached");

		FauxTranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(bPush && !bHitMax)
		{
			bHitMax = true;
			UMagnetDronePushableEffectEventHandler::Trigger_OnConstrainHitMax(this);
		}
		else if (!bPush)
			UMagnetDronePushableEffectEventHandler::Trigger_OnConstrainHitMin(this);
	}

	UFUNCTION()
	private void MagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		bPush = true;
		FauxTranslateComp.SpringStrength = 0;
		SpringStrength = 0;
		Strength = 1000;

		FVector Force = FauxTranslateComp.WorldLocation - ForceDirection.WorldLocation;
		Force.Normalize();
		Force *= Strength; 
		FauxTranslateComp.ApplyImpulse(ForceDirection.WorldLocation,Force);
		UMagnetDronePushableEffectEventHandler::Trigger_OnPushStart(this);
	}

	UFUNCTION()
	private void MagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		bPush = false;
		bHitMax = false;
		Strength = 0;
		SpringStrength = 0;
		FauxTranslateComp.SpringStrength = 0;
		UMagnetDronePushableEffectEventHandler::Trigger_OnPushReset(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPush)
		{
			FVector Force = FauxTranslateComp.WorldLocation - ForceDirection.WorldLocation;
			Force.Normalize();
			Strength = Math::FInterpTo(Strength,5000,DeltaSeconds,100);
			Force *= Strength;
			FauxTranslateComp.ApplyForce(ForceDirection.WorldLocation,Force);
		}
		else
		{
			SpringStrength = Math::FInterpConstantTo(SpringStrength,5,DeltaSeconds,1);
			FauxTranslateComp.SpringStrength = SpringStrength;
		}
	}
}

class UMagnetDronePushableEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnPushStart() {}
	UFUNCTION(BlueprintEvent)
	void OnPushReset() {}
	UFUNCTION(BlueprintEvent)
	void OnConstrainHitMax() {}
	UFUNCTION(BlueprintEvent)
	void OnConstrainHitMin() {}
};
