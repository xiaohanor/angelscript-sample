event void FSanctuaryZoeBoeArrowSignature();
class ASanctuaryBossZoeBowArrow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ArrowRollRoot;

	UPROPERTY(DefaultComponent, Attach = ArrowRollRoot)
	UStaticMeshComponent ArrowMesh;

	UPROPERTY(DefaultComponent, Attach = ArrowRollRoot)
	UStaticMeshComponent GlowingArrowMesh;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BloodExplosion;

	UPROPERTY()
	FSanctuaryZoeBoeArrowSignature OnHit;

	float Velocity;
	bool bFired = false;
	bool bHasCompanions = false;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	FVector ArrowStartLocation;
	FQuat ArrowStartRotation; 
	FQuat ArrowTargetRotation;
	

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ArrowSpinTimeLike;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	UMaterialInstance ArrowMI;
	UMaterialInstanceDynamic ArrowMID;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArrowStartLocation = ActorLocation;
		ArrowStartRotation = GetActorTransform().GetRotation();
		ArrowSpinTimeLike.BindUpdate(this, n"BindSpinUpdate");

		ArrowMID = Material::CreateDynamicMaterialInstance(this, ArrowMI);
		ArrowMesh.SetMaterial(0, ArrowMID);
	}

	void Activate()
	{
		QueueComp.Empty();
		QueueComp.Event(this, n"BP_GlowArrow");
		QueueComp.Duration(1.0, this, n"DrillUpdate");
		//QueueComp.Event(this, n"BP_UnGlowArrow");
	}

	UFUNCTION(BlueprintEvent)
	private void BP_GlowArrow(){}

	UFUNCTION(BlueprintEvent)
	private void BP_UnGlowArrow(){}

	UFUNCTION()
	private void DrillUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
		ArrowMID.SetScalarParameterValue(n"Opacity", Math::Lerp(100.0, 8.5, CurrentValue));
		ArrowRollRoot.SetRelativeRotation(FRotator(0.0, -90.0, 1080.0 * CurrentValue));
	}

	UFUNCTION()
	private void BindSpinUpdate(float CurrentValue)
	{
		ArrowRollRoot.SetRelativeRotation(FRotator(0.0, -90.0, 360.0 * CurrentValue));
	}

	UFUNCTION()
	 void TimeToShoot()
	{
		//PrintToScreen("WE HAVE SHOOTED :)", 5.0);
		bFired = true;

		ActionQueComp.Duration(2.0, this, n"UpdateArrowShot");
		ActionQueComp.Event(this, n"HitTarget");

	}


	UFUNCTION()
	private void UpdateArrowShot(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		FQuat Rotation = FQuat::Slerp(ArrowStartRotation, ArrowTargetRotation, AlphaValue);

		ArrowRollRoot.SetRelativeRotation(FRotator(0.0, -90.0, AlphaValue * 400.0));
		//SetActorRotation(Rotation);
	}

	UFUNCTION()
	void HitTarget()
	{
		//PrintToScreen("TargetHit", 5.0);

		bFired = false;
		OnHit.Broadcast();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_HitTarget(){}




};