struct FSanctuaryLightableCandleEventParams
{
	UPROPERTY()
	USanctuaryLightableCandleComponent CandleLightComp;
}

UCLASS(Abstract)
class USanctuaryLightableCandleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandleLit(FSanctuaryLightableCandleEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandleUnlit()
	{
	}

};	
class ASanctuaryLightableCandle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CandleBase;

	UPROPERTY(DefaultComponent)
	USanctuaryLightableCandleComponent CandleLightComp;

	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComponent;
	default LightBirdTargetComponent.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DarkPortalTargetComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;
	default LightBirdResponseComponent.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SmokeVFX;

	bool bLit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"OnTentacled");

		DarkPortalTargetComponent.Disable(this);
	}

	UFUNCTION()
	private void OnTentacled(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (bLit)
		{
			LightBirdTargetComponent.Enable(this);
			CandleLightComp.SetVisibility(false);
			SmokeVFX.Activate();
			bLit = false;
			Timer::SetTimer(this, n"StartSmoke", 1.0);
			Timer::SetTimer(this, n"StopSmoke", 3.0);
			DarkPortalTargetComponent.Disable(this);
			USanctuaryLightableCandleEventHandler::Trigger_OnCandleUnlit(this);
		}
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		CandleLightComp.SetVisibility(true);
		LightBirdTargetComponent.Disable(this);
		SmokeVFX.Deactivate();
		bLit = true;
		DarkPortalTargetComponent.Enable(this);
		LightBirdCompanion::GetLightBirdCompanion().CompanionComp.State = ELightBirdCompanionState::Follow;
		FSanctuaryLightableCandleEventParams Params;
		Params.CandleLightComp = CandleLightComp;
		USanctuaryLightableCandleEventHandler::Trigger_OnCandleLit(this, Params);
	}
	
	UFUNCTION()
	private void StartSmoke()
	{
		if (!bLit)
			SmokeVFX.Activate();
	}

	UFUNCTION()
	private void StopSmoke()
	{
		if (!bLit)
			SmokeVFX.Deactivate();
	}
};