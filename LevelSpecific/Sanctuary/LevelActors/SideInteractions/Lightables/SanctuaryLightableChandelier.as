UCLASS(Abstract)
class USanctuaryLightableChandelierEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandleLit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandleUnlit()
	{
	}

};	
class ASanctuaryLightableChandelier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightComponentsRoot;

	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComponent;
	default LightBirdTargetComponent.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;
	default LightBirdResponseComponent.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightBirdFollowComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem LightUpVFX;

	FHazeRuntimeSpline LightySpline;
	TArray<UStaticMeshComponent> LightMeshies;
	float LightNextCooldown = 0.0;
	
	bool bIlluminating = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightComponentsRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, LightMeshies);
		for (int iLight = 0; iLight < LightMeshies.Num(); ++iLight)
		{
			UStaticMeshComponent LightMeshy = LightMeshies[iLight];
			LightMeshy.SetVisibility(false, true);
		}

		TArray<FVector> Points;
		Points.Add(LightBirdTargetComponent.WorldLocation);
		
		int Granularity = 10;
		float DegreesPerStep = 360.0 / Granularity;
		float Radius = 200.0;
		FVector CenterLocation = ActorLocation + FVector(0.0, 0.0, 100.0);
		for (int iStep = 0; iStep < Granularity; ++iStep)
		{
			FVector OutwardsDir = Math::RotatorFromAxisAndAngle(ActorUpVector, DegreesPerStep * iStep).ForwardVector;
			Points.Add(CenterLocation + OutwardsDir * Radius);
		}

		LightySpline.SetPoints(Points);
		FVector FromFirstToSecond = Points[1] - Points[0];
		LightySpline.SetCustomEnterTangentPoint(FromFirstToSecond);

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"StartIlluminate");
	}

	UFUNCTION()
	private void StartIlluminate()
	{
		bIlluminating = true;
		LightBirdFollowComp.SetWorldLocation(LightBirdTargetComponent.WorldLocation);
		LightBirdTargetComponent.Disable(this);
		USanctuaryLightableChandelierEventHandler::Trigger_OnCandleLit(this);

		// todo(ylva) swirl around chandelier
		LightBirdCompanion::GetLightBirdCompanion().CompanionComp.State = ELightBirdCompanionState::Follow;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// LightySpline.DrawDebugSpline();

		if (bIlluminating)
		{
			LightNextCooldown -= DeltaSeconds;
			if (LightNextCooldown < 0.0)
			{
				LightNextCooldown = 0.2;
				for (int iLight = 0; iLight < LightMeshies.Num(); ++iLight)
				{
					UStaticMeshComponent LightMeshy = LightMeshies[iLight];
					if (LightMeshy.IsVisible())
						continue;

					LightMeshy.SetVisibility(true, true);

					if (LightUpVFX != nullptr)
						Niagara::SpawnOneShotNiagaraSystemAtLocation(LightUpVFX, LightMeshy.WorldLocation);
					break;
				}
			}
		}
	}
};