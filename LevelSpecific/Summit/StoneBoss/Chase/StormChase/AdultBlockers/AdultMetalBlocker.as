class AAdultMetalBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	UPROPERTY(EditAnywhere)
	bool bStartInactive = true;

	float FadeAlpha;

	UMaterialInstanceDynamic DynamicMat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartInactive)
			FadeAlpha = 0;
		else
			FadeAlpha = 1;
	
		ResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshComp.SetScalarParameterValueOnMaterials(n"Dissolve", FadeAlpha);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		UAdultMetalBlockerEffectHandler::Trigger_OnAcidHit(this, FAdultMetalBlockerOnAcidHitParams(ActorLocation));
		AddActorDisable(this);
	}
};