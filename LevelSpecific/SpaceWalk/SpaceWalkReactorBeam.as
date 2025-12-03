class ASpaceWalkReactorBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UBillboardComponent EndPoint;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Beam;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BeamTwo;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BeamStart;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BeamStartTwo;

	UPROPERTY(DefaultComponent)
	USpotLightComponent LaserLight01;

	UPROPERTY(DefaultComponent)
	USpotLightComponent LaserLight02;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ChargeMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ChargeMeshTwo;

	UPROPERTY(DefaultComponent)
	UDeathTriggerComponent DeathTrigger;

	FVector StartScaleBeam = FVector(0.1,0.1,0.1);

	FVector EndScaleBeam = FVector(5,5,65);

	FVector StartScaleCharge = FVector(0.1,0.1,0.1);

	FVector EndScaleCharge = FVector(7,7,7);

	UPROPERTY(EditAnywhere)
	float LightIntensity;

	FHazeTimeLike BeamLike;
	default BeamLike.Duration = 0.2;
	default BeamLike.UseLinearCurveZeroToOne();

	FHazeTimeLike ChargeBall;
	default ChargeBall.Duration = 5.0;
	default ChargeBall.UseLinearCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent BeamFF;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> BeamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathTrigger.DisableDeathTrigger(this);

		Timer::SetTimer(this, n"StartLaser", 5.0);

		ChargeBall.BindUpdate(this, n"ChargeTheBall");

		BeamLike.BindUpdate(this, n"StartBeam");

		ChargeBall.PlayFromStart();

		USpaceWalkReactorBeamEventHandler::Trigger_StartCharge(this);
	}

	UFUNCTION()
	private void StartBeam(float CurrentValue)
	{
		Beam.SetRelativeScale3D(Math::Lerp(StartScaleBeam,EndScaleBeam, CurrentValue));
		BeamTwo.SetRelativeScale3D(Math::Lerp(StartScaleBeam,EndScaleBeam, CurrentValue));
		LaserLight01.SetIntensity(Math::Lerp(0.0,LightIntensity, CurrentValue));
		LaserLight02.SetIntensity(Math::Lerp(0.0,LightIntensity, CurrentValue));
	}

	UFUNCTION()
	private void ChargeTheBall(float CurrentValue)
	{
		ChargeMesh.SetRelativeScale3D(Math::Lerp(StartScaleCharge,EndScaleCharge, CurrentValue));
		ChargeMeshTwo.SetRelativeScale3D(Math::Lerp(StartScaleCharge,EndScaleCharge, CurrentValue));
	}

	UFUNCTION()
	private void StartLaser()
	{
		LaserLight01.CastShadows = Game::IsShaderQualityAtLeastHigh();
		LaserLight02.CastShadows = Game::IsShaderQualityAtLeastHigh();

		BeamLike.PlayFromStart();

	//	Beam.SetVisibility(true);

		DeathTrigger.EnableDeathTrigger(this);

		BeamFF.Play();

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(BeamShake,this, ActorCenterLocation, 2500, 7000, 1.0);
		}

		BeamStart.Activate(true);

		BeamStartTwo.Activate(true);

		ChargeMesh.SetVisibility(false);

		ChargeMeshTwo.SetVisibility(false);
		
		USpaceWalkReactorBeamEventHandler::Trigger_StartBeam(this);

		Timer::SetTimer(this, n"StopLaser", 3.0);
	}

	UFUNCTION()
	private void StopLaser()
	{
		BeamLike.ReverseFromEnd();

		USpaceWalkReactorBeamEventHandler::Trigger_StopBeam(this);

	//	Beam.SetVisibility(false);

		DeathTrigger.DisableDeathTrigger(this);

		Timer::SetTimer(this, n"StartLaser", 3.0);

		ChargeMesh.SetVisibility(true);

		ChargeMeshTwo.SetVisibility(true);

		ChargeBall.PlayFromStart();

		USpaceWalkReactorBeamEventHandler::Trigger_StartCharge(this);
	}
};