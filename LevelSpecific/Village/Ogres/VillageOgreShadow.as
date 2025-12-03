event void FVillageOgreShadowEvent();

class AVillageOgreShadow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeDecalComponent DecalComp;

	UPROPERTY()
	FVillageOgreShadowEvent OnShadowCompleted;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShadowTimeLike;
	default ShadowTimeLike.Duration = 1.0;
	default ShadowTimeLike.bCurveUseNormalizedTime = true;
	default ShadowTimeLike.Curve.AddDefaultKey(0.0, 0.0);
	default ShadowTimeLike.Curve.AddDefaultKey(1.0, 1.0);

	UMaterialInstanceDynamic DynamicMat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShadowTimeLike.BindUpdate(this, n"UpdateShadow");
		ShadowTimeLike.BindFinished(this, n"FinishShadow");

		DynamicMat = DecalComp.CreateDynamicMaterialInstance();
		DynamicMat.SetScalarParameterValue(n"Opacity", 0.0);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateShadow(float CurValue)
	{
		float Opacity = Math::Lerp(0.0, 2.0, CurValue);
		DynamicMat.SetScalarParameterValue(n"Opacity", Opacity);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishShadow()
	{
		OnShadowCompleted.Broadcast();
	}

	UFUNCTION()
	void ActivateShadow()
	{
		ShadowTimeLike.PlayFromStart();
	}
}