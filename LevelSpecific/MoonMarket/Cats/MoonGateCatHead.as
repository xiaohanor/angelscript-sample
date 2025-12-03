event void FOnMoonGateCatHeadActivated();

class AMoonGateCatHead : AHazeActor
{
	UPROPERTY()
	FOnMoonGateCatHeadActivated OnMoonGateCatHeadActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CatTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CompletedEffect;
	default CompletedEffect.SetAutoActivate(false);

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor OriginalColour;

	float CurrentEmissive = 0.2;
	float TargetEmissive = 20.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMat = MeshComp.CreateDynamicMaterialInstance(0);
		OriginalColour = DynamicMat.GetVectorParameterValue(n"EmissiveTint");
		DynamicMat.SetVectorParameterValue(n"EmissiveTint", OriginalColour * CurrentEmissive);
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentEmissive = Math::FInterpConstantTo(CurrentEmissive, TargetEmissive, DeltaSeconds, TargetEmissive / 3);
		DynamicMat.SetVectorParameterValue(n"EmissiveTint", OriginalColour * CurrentEmissive);
	}

	void CatHeadActivated(UMaterialInterface Mat)
	{
		CompletedEffect.Activate();
		UMoonGateHeadEventHandler::Trigger_OnCatHeadStartedGlowing(this, FOnCatHeadActivatedParams(ActorLocation, MeshComp));
		Timer::SetTimer(this, n"DelayedBroadcast", 1.0);
		SetActorTickEnabled(true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Distance = (Player.ActorLocation - ActorLocation).Size();
			float Multiplier = Math::Saturate(700.0 / Distance);
			if (Multiplier > 0.6)
				Multiplier = 1.0;
			else if (Multiplier < 0.1)
				Multiplier = 0.0;

			Player.PlayForceFeedback(Rumble, false, false, this, 0.1 * Multiplier);
		}
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		SetCatHeadEndState();
	}

	UFUNCTION()
	void SetCatHeadEndState()
	{
		CompletedEffect.Activate();
		UMoonGateHeadEventHandler::Trigger_OnCatHeadStartedGlowing(this, FOnCatHeadActivatedParams(ActorLocation, MeshComp));
	}

	UFUNCTION()
	void DelayedBroadcast()
	{
		OnMoonGateCatHeadActivated.Broadcast();
	}
};