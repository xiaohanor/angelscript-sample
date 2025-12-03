event void FOnSolarFlareBatteryPerchActivated(AHazePlayerCharacter Player);
event void FOnSolarFlareBatteryPerchDeactivated();

class ASolarFlareBatteryPerch : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareBatteryPerchActivated OnSolarFlareBatteryPerchActivated;

	UPROPERTY()
	FOnSolarFlareBatteryPerchDeactivated OnSolarFlareBatteryPerchDeactivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BarryMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HolderMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LightUpMesh;

	UPROPERTY(EditAnywhere)
	APerchPointActor PerchPoint;

	UPROPERTY(EditAnywhere)
	ASolarFlareBatteryShieldIndicator Indicator;

	UPROPERTY(EditAnywhere)
	bool bPermaOn = true;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;
	
	UPROPERTY()
	UMaterialInterface OnEmissiveMat;

	UMaterialInterface OffEmissiveMat;
	
	UPROPERTY(EditAnywhere)
	FVector FallPoint = FVector(0,0,80);

	FVector StartLoc;

	float MoveSpeed = 400.0;
	UPROPERTY(EditAnywhere)
	float ActivationDelayDuration = 0.3;
	UPROPERTY(EditAnywhere)
	bool bUseActivationDelayAfterWaveHit = false;
	float ActivationAllowedTime;

	TPerPlayer<bool> bPlayersOn;
	bool bSwitchMaterialOff = true;
	bool bIsOn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerchingEvent");
		PerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");
		OffEmissiveMat = LightUpMesh.GetMaterial(0);
		StartLoc = BarryMesh.RelativeLocation;
		FallPoint = StartLoc - FallPoint;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Target = StartLoc;

		if (bIsOn)
			Target = FallPoint;

		BarryMesh.RelativeLocation = Math::VInterpConstantTo(BarryMesh.RelativeLocation, Target, DeltaSeconds, MoveSpeed);
	}

	UFUNCTION()
	private void OnPlayerStartedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent CurrentPerchPoint)
	{
		if (!bIsOn)
			Player.PlayForceFeedback(Rumble, false, false, this);

		bPlayersOn[Player] = true;
		TurnOn(Player);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent CurrentPerchPoint)
	{
		bPlayersOn[Player] = false;

		if (!bPermaOn)
		{
			if (!bPlayersOn[Player] && !bPlayersOn[Player.OtherPlayer])
			{
				TurnOff();
				Player.PlayForceFeedback(Rumble, false, false, this);
			}
		}
	}

	void TurnOn(AHazePlayerCharacter Player)
	{	
		if (Time::GameTimeSeconds < ActivationAllowedTime && bUseActivationDelayAfterWaveHit)
			return;

		if(bIsOn)
			return;
		
		LightUpMesh.SetMaterial(0, OnEmissiveMat);
		bSwitchMaterialOff = false;		
		bIsOn = true;
		Indicator.TurnOn();
		
		FSolarFlareBatteryPerchEffectHandlerParams Params;
		Params.Location = ActorLocation;
		Params.IndicatorLocation = Indicator.ActorLocation;
		USolarFlareBatteryPerchEffectHandler::Trigger_BatteryOn(this, Params);

		OnSolarFlareBatteryPerchActivated.Broadcast(Player);
	}

	void TurnOff()
	{
		if(!bIsOn)
			return;

		bSwitchMaterialOff = true;
		bIsOn = false;
		Indicator.TurnOff();
		LightUpMesh.SetMaterial(0, OffEmissiveMat);

		FSolarFlareBatteryPerchEffectHandlerParams Params;
		Params.Location = ActorLocation;
		Params.IndicatorLocation = Indicator.ActorLocation;
		USolarFlareBatteryPerchEffectHandler::Trigger_BatteryOff(this, Params);		

		ActivationAllowedTime = Time::GameTimeSeconds + ActivationDelayDuration;

		OnSolarFlareBatteryPerchDeactivated.Broadcast();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (Indicator != nullptr)
			Debug::DrawDebugLine(PerchPoint.ActorLocation, Indicator.ActorLocation, FLinearColor::Yellow, 10.0);
	}
#endif
};