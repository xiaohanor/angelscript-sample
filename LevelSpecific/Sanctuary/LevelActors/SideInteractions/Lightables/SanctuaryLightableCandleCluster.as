	
class ASanctuaryLightableCandleCluster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CandleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryLightableCandleComponent Light1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryLightableCandleComponent Light2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryLightableCandleComponent Light3;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryLightableCandleComponent Light4;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryLightableCandleClusterBirdTargetSpot LightSpot = nullptr;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (LightSpot == nullptr)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (LightSpot.bIlluminating)
		{
			MaybeLight(Light1);
			MaybeLight(Light2);
			MaybeLight(Light3);
			MaybeLight(Light4);

			if (Light1.bLit && Light2.bLit && Light3.bLit && Light4.bLit)
				SetActorTickEnabled(false);
		}
	}

	private void MaybeLight(USanctuaryLightableCandleComponent CandleComp)
	{
		if (!CandleComp.bLit && LightSpot.ActorLocation.Distance(CandleComp.WorldLocation) < LightSpot.Reach)
		{
			CandleComp.bLit = true;
			CandleComp.SetVisibility(true, true);
			FSanctuaryLightableCandleEventParams Params;
			Params.CandleLightComp = CandleComp;
			USanctuaryLightableCandleEventHandler::Trigger_OnCandleLit(this, Params);
		}
	}
};