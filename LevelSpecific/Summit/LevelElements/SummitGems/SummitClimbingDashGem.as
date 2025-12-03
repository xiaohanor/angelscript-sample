class ASummitClimbingDashGem : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent SummitCol;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailGeckoClimbDashImpactResponseComponent DashImpact;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DestructionEffectScale = 1.0;

	UPROPERTY(EditAnywhere, Category = Audio)
	UHazeAudioEvent SmashEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = Audio, Meta = (ShowOnlyInnerProperties, EditCondition = "SmashEvent != nullptr"))
	FHazeAudioFireForgetEventParams AudioEventParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DashImpact.OnHitByDash.AddUFunction(this, n"OnHitByDash");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByDash(FTeenDragonGeckoClimbDashImpactParams Params)
	{
		FOnSummitGemDestroyedParams DestroyParams;
		DestroyParams.Location = ActorLocation;
		DestroyParams.Rotation = ActorRotation;
		DestroyParams.Scale = DestructionEffectScale;
		USummitGemDestructionEffectHandler::Trigger_DestroyRegularGem(this, DestroyParams);

		if(SmashEvent != nullptr)
		{
			AudioEventParams.Transform = Game::GetZoe().GetActorTransform();
			AudioComponent::PostFireForget(SmashEvent, AudioEventParams);
		}
		AddActorDisable(this);
	}
};