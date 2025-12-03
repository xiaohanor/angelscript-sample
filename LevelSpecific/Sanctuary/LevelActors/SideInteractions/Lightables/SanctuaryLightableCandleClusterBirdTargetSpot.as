UCLASS(Abstract)
class USanctuaryLightableCandleClusterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandlesLit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandlesUnlit()
	{
	}

};
class ASanctuaryLightableCandleClusterBirdTargetSpot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComponent;
	default LightBirdTargetComponent.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;
	default LightBirdResponseComponent.bExclusiveAttachedIllumination = true;

	float Reach = 0.0;
	bool bIlluminating = false;

	bool bForceIlluminating = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComponent.OnAttached.AddUFunction(this, n"StartIlluminate");
		LightBirdResponseComponent.OnDetached.AddUFunction(this, n"StopIlluminate");
	}

	UFUNCTION()
	private void StartIlluminate()
	{
		bIlluminating = true;
		USanctuaryLightBirdCompanionComponent CompanionComp = USanctuaryLightBirdCompanionComponent::Get(LightBirdCompanion::GetLightBirdCompanion());
		CompanionComp.ForceIlluminators.Add(this);
		LightBirdTargetComponent.Disable(this);
		bForceIlluminating = true;

		USanctuaryLightableCandleClusterEventHandler::Trigger_OnCandlesLit(this);
	}

	UFUNCTION()
	private void StopIlluminate()
	{
		if (bForceIlluminating)
		{
			USanctuaryLightBirdCompanionComponent CompanionComp = USanctuaryLightBirdCompanionComponent::Get(LightBirdCompanion::GetLightBirdCompanion());
			CompanionComp.ForceIlluminators.Remove(this);
			bForceIlluminating = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIlluminating)
		{
			const float ReachingSpeed = 200.0;
			Reach += DeltaSeconds * ReachingSpeed;
			if (Reach > ReachingSpeed * 0.5 && bForceIlluminating)
			{
				bForceIlluminating = false;
				USanctuaryLightBirdCompanionComponent CompanionComp = USanctuaryLightBirdCompanionComponent::Get(LightBirdCompanion::GetLightBirdCompanion());
				CompanionComp.ForceIlluminators.Remove(this);
			}
		}
	}
};