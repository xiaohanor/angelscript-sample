class ASanctuaryRotatingStatue : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.bWorldSpace = false;
	default ForceComp.RelativeLocation = FVector::ForwardVector * 500.0;
	default ForceComp.Force = FVector::RightVector * -25.0;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent StatueMesh;

	UPROPERTY(DefaultComponent, Attach = StatueMesh)
	UStaticMeshComponent PortalPlaceableMesh;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent BirdRespComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalPhysicsComp;

	UPROPERTY(EditAnywhere)
	bool bIsReverse = false;

	UMaterialInstanceDynamic StatueLightMID;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;


	UPROPERTY()
	UMaterialInterface StatueLightMaterial;

	FHazeAcceleratedFloat ChargeTime;
	float ChargeDuration = 2.0;
	float TargetStatueLightValue = 1.0;

	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		BirdRespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		BirdRespComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		ChargeTime.SnapTo(1.0);
		StatueLightMID = Material::CreateDynamicMaterialInstance(this, StatueLightMaterial);
		StatueLightMID.SetScalarParameterValue(n"EMISSIVE_Smoothstep", ChargeTime.Value);
		StatueMesh.SetOverlayMaterial(StatueLightMID);
	

		if (bIsReverse)
			ForceComp.Force *= -1.0;

		ForceComp.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		bIsMoving = true;
		TargetStatueLightValue = 0.3;
		Pivot.Friction = 1.0;
		ForceComp.RemoveDisabler(this);
		HandleMaterialActivated();
		URotatingStatueEffectEventHandler::Trigger_StartRotating(this);
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		TargetStatueLightValue = 1.0;
		bIsMoving = false;
		Pivot.Friction = 6.0;
		ForceComp.AddDisabler(this);
		HandleMaterialDeactivated();
		URotatingStatueEffectEventHandler::Trigger_StopRotating(this);
	}

	UFUNCTION(BlueprintEvent)
	private void HandleMaterialActivated()
	{

	}

	UFUNCTION(BlueprintEvent)
	private void HandleMaterialDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		StatueLightMID.SetScalarParameterValue(n"EMISSIVE_Smoothstep", ChargeTime.Value);

		ChargeTime.AccelerateTo(TargetStatueLightValue, ChargeDuration, DeltaSeconds);
			
	}
};