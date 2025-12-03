event void FBirthDayCandleLitSignature(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ADentistBirthdayCandle : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UNiagaraComponent CandleFireVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StarLine1Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StarLine2Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StarCircleRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDentistToothDashAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent ToothResponseComp;

	UPROPERTY()
	UNiagaraSystem CandleFireBurstVFX;

	UPROPERTY()
	UNiagaraSystem CandleFireSmokeBurstVFX;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FBirthDayCandleLitSignature OnBirthDayCandleLit;

	UPROPERTY()
	FHazeTimeLike StarTimeLike;
	default StarTimeLike.Duration = 2.0;
	default StarTimeLike.UseSmoothCurveZeroToOne();

	ADentistBirthdayCandleManager Manager;
	float LitDuration = 5.5;
	float LitTime = -1;
	bool bStayLit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ToothResponseComp.OnDashedInto.AddUFunction(this, n"HandleDashedInto");
		StarTimeLike.BindUpdate(this, n"StarTimeLikeUpdate");
		StarLine1Root.SetRelativeScale3D(FVector(SMALL_NUMBER));
		StarLine2Root.SetRelativeScale3D(FVector(SMALL_NUMBER));
		StarCircleRoot.SetRelativeLocation(FVector::UpVector * -150.0);

		Manager = Cast<ADentistBirthdayCandleManager>(AttachParentActor);
		if (Manager != nullptr)
		{
			OnBirthDayCandleLit.AddUFunction(Manager, n"HandleCandleLit");
			Manager.Candles.Add(this);
		}
	}

	UFUNCTION(DevFunction)
	void DevLight()
	{
		CrumbLight(Game::Mio, FVector::ZeroVector);
		LitDuration = 200000.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(LitTime > 0 && !IsLit())
				CrumbPutOut(false);
		}
	}

	UFUNCTION()
	private void HandleDashedInto(AHazePlayerCharacter DashPlayer, FVector Impulse, FHitResult Impact)
	{
		if(!DashPlayer.HasControl())
			return;

		CrumbLight(DashPlayer, Impulse);
	}

	bool IsLit() const
	{
		if(bStayLit)
			return true;

		if(LitTime < 0)
			return false;

		return Time::GetGameTimeSince(LitTime) < LitDuration;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLight(AHazePlayerCharacter DashPlayer, FVector Impulse)
	{
		ConeRotateComp.ApplyImpulse(DashPlayer.ActorCenterLocation, Impulse);
		CandleFireVFXComp.Activate(true);
		Niagara::SpawnOneShotNiagaraSystemAttached(CandleFireBurstVFX, CandleFireVFXComp);
		
		LitTime = Time::GameTimeSeconds;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(DashPlayer);
		OnBirthDayCandleLit.Broadcast(DashPlayer);
		SetActorTickEnabled(true);

		FDentistBirthdayCandleOnLightEventData EventData;
		EventData.LitCandles = Manager.GetLitCandleCount();
		UDentistBirthdayCandleEventHandler::Trigger_OnLight(this, EventData);
	}

	UFUNCTION(BlueprintCallable)
	void PutOut(bool bForce)
	{
		if(!HasControl())
			return;

		CrumbPutOut(bForce);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPutOut(bool bForce)
	{
		CandleFireVFXComp.Deactivate();
		Niagara::SpawnOneShotNiagaraSystemAttached(CandleFireSmokeBurstVFX, CandleFireVFXComp);

		LitTime = -1;

		if(bForce)
			bStayLit = false;

		SetActorTickEnabled(false);

		FDentistBirthdayCandleOnUpOutEventData EventData;
		EventData.LitCandles = Manager.GetLitCandleCount();
		UDentistBirthdayCandleEventHandler::Trigger_OnPutOut(this, EventData);
	}

	UFUNCTION(BlueprintCallable)
	void HideVFXInCutscene()
	{
		CandleFireVFXComp.Deactivate();
	}

	UFUNCTION()
	void CreateStar()
	{
		StarTimeLike.Play();
	}

	UFUNCTION()
	private void StarTimeLikeUpdate(float CurrentValue)
	{
		FVector Scale = FVector(1.0, CurrentValue, 1.0);
		StarLine1Root.SetWorldScale3D(Scale);
		StarLine2Root.SetWorldScale3D(Scale);
		StarCircleRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-150.0, 0.0, CurrentValue));
	}
};