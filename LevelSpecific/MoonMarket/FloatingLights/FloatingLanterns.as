class AFloatingLanterns : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoonMarketBobbingSceneComponent BobbingComponent;
	default BobbingComponent.BobAmount = 7.0;

	UPROPERTY(DefaultComponent, Attach = BobbingComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 3.0;
	default TranslateComp.SpringStrength = 0.5;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsConeRotateComponent ConeComp;
	default ConeComp.Friction = 3.0;
	default ConeComp.SpringStrength = 0.5;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 50.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.25;

	UPROPERTY(DefaultComponent, Attach = BobbingComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = BobbingComponent)
	UPerchPointComponent PerchComp;
	default PerchComp.bAllowGrappleToPoint = false;
	default PerchComp.ActivationRange = 450.0;

	UPROPERTY(DefaultComponent, Attach = PerchComp)
	UPerchEnterByZoneComponent EnterZone;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(DefaultComponent, Attach = BobbingComponent)
	UNiagaraComponent Glow;

	UMaterialInstanceDynamic DynamicMat;
	float EmissiveStrengthMult = 1;
	float TargetEmissiveStrengthMult = 1;
	float InterpSpeed = 3;
	FLinearColor EmissiveTint;

	bool bIsPerchedOn = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartPerch");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStopPerch");

		DynamicMat =  Material::CreateDynamicMaterialInstance(this, MeshComp.GetMaterial(0));
		MeshComp.SetMaterial(0, DynamicMat);
		EmissiveTint = DynamicMat.GetVectorParameterValue(n"EmissiveTint");
		Glow.SetFloatParameter(n"Opacity", EmissiveStrengthMult);
	}

	UFUNCTION()
	private void OnPlayerStartPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		InterpSpeed = 150;
		TargetEmissiveStrengthMult = 8;
		BobbingComponent.WeightTargetOffset = -30;
		UFloatingLanternEventHandler::Trigger_OnPlayerLanded(this);
	}

	UFUNCTION()
	private void OnPlayerStopPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if(!PerchPoint.IsPlayerOnPerchPoint[Player.OtherPlayer])
		{
			TargetEmissiveStrengthMult = 1;
			InterpSpeed = 5;
		}
		
		BobbingComponent.WeightTargetOffset = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Math::Abs(EmissiveStrengthMult - TargetEmissiveStrengthMult) > KINDA_SMALL_NUMBER)
		{
			EmissiveStrengthMult = Math::FInterpConstantTo(EmissiveStrengthMult, TargetEmissiveStrengthMult, DeltaSeconds, InterpSpeed);
			DynamicMat.SetVectorParameterValue(n"EmissiveTint", EmissiveTint * EmissiveStrengthMult);
			Glow.SetFloatParameter(n"Opacity", EmissiveStrengthMult );
		}
	}
};