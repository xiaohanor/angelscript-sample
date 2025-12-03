struct FStormSiegeLightningStrikeParams
{
	UPROPERTY()
	FVector Start;

	UPROPERTY()
	FVector End;

	UPROPERTY()
	float BeamWidth;

	UPROPERTY()
	float NoiseStrength;

	UPROPERTY()
	USceneComponent AttachComp;
}

struct FStormSiegeLightningLoopParams
{
	UPROPERTY()
	FVector StartPoint;

	UPROPERTY()
	FVector EndPoint;
}

struct FStormSiegeRockImpactParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Direction;
}

struct FStormLightningSplineEffectParams
{
	UPROPERTY()
	UNiagaraComponent LightningNiagaraComp;

	UPROPERTY()
	float BuildUpAlpha = 0.0;

	UPROPERTY()
	float Width = 0.0;
}

class UStormSiegeLightningEffectsHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void LightningStrike(FStormSiegeLightningStrikeParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartLightningLoop(FStormSiegeLightningLoopParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopLightningLoop(FStormSiegeLightningLoopParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RockImpact(FStormSiegeRockImpactParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateSpline(FStormLightningSplineEffectParams Params) 
	{
		SplineParams = Params;
		SplineParams.LightningNiagaraComp.Activate();
		bRunEffects = true;
		EffectAlpha = 0.0;
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeactivateSpline() 
	{
		SplineParams.LightningNiagaraComp.Deactivate();
		bRunEffects = false;
	}

	//Width
	//BuildUpTime

	UPROPERTY()
	FStormLightningSplineEffectParams SplineParams;
	UPROPERTY()
	float EffectAlpha;
	UPROPERTY()
	float WidthAlpha;
	bool bRunEffects;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bRunEffects)
			return;
		
		EffectAlpha += SplineParams.BuildUpAlpha * DeltaTime;
		float Width = SplineParams.Width * EffectAlpha;
		SplineParams.LightningNiagaraComp.SetFloatParameter(n"BuildUpAlpha", EffectAlpha);
		SplineParams.LightningNiagaraComp.SetFloatParameter(n"Width", Width);

		if (EffectAlpha >= 1.0)
		{
			DeactivateSpline();

		}
	}
}