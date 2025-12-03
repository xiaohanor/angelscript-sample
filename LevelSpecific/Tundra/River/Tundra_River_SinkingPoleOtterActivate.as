UCLASS(Abstract)
class ATundra_River_SinkingPoleOtterActivate : APoleClimbActor
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UTundraPlayerOtterSonarBlastTargetable SonarBlastTargetable;
	default SonarBlastTargetable.RelativeLocation = FVector(0.0, 0.0, 1500.0);
	default SonarBlastTargetable.ActionShape.InitializeAsSphere(243.841202);
	default SonarBlastTargetable.FocusShape.InitializeAsSphere(2000.0);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;

	UPROPERTY()
	FHazeTimeLike TimeLike;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float DeactivationAnticipationAlpha = 0.7;

	UPROPERTY(EditAnywhere, Category = "Timing")
	float ActivatedDuration = TimeLike.Duration;

	FVector OriginalLocation;
	FVector TargetLocation;
	TOptional<float> TimeOfStartPredicting;
	const float PredictSpeed = 0.2;
	bool bCalledTurnOnEvent = false;
	bool bCalledTurnOffEvent = false;
	bool bShaking = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorControlSide(Game::Zoe);
		
		SonarBlastTargetable.OnTriggered.AddUFunction(this, n"OnSonarBlastTargetableTriggered");
		OriginalLocation = ActorLocation;
		TargetLocation = OriginalLocation + FVector::UpVector * 900.0;
		PerchPointComp.DisableForPlayer(Game::Zoe, this);
		TimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		TimeLike.BindFinished(this, n"CrumbOnTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShaking)
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50);
			SetActorRelativeRotation(FRotator(0.2, 0.3, 0) * SineRotate);
		}

		if(HasControl())
			return;

		float Alpha = SyncedAlpha.Value;
		if(TimeOfStartPredicting.IsSet())
		{
			float TimeSinceStartPredicting = Time::GetGameTimeSince(TimeOfStartPredicting.Value);
			float PredictAlpha = TimeSinceStartPredicting * PredictSpeed;
			if(Alpha > PredictAlpha)
				TimeOfStartPredicting.Reset();
			else
				Alpha = PredictAlpha;
		}

		SetLocationBasedOnAlpha(Alpha);
	}

	UFUNCTION()
	private void OnSonarBlastTargetableTriggered(UTundraPlayerOtterSonarBlastTargetable Targetable)
	{
		SonarBlastTargetable.DisableForPlayer(Game::Mio, this);
		if(HasControl())
		{
			TimeLike.PlayFromStart();
			
			Timer::SetTimer(this, n"StartShake", ActivatedDuration * DeactivationAnticipationAlpha);
			bCalledTurnOnEvent = false;
			bCalledTurnOffEvent = false;
		}
		else
		{
			TimeOfStartPredicting.Set(Time::GetGameTimeSeconds());
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartShake()
	{
		bShaking = true;
		Timer::SetTimer(this, n"StopShake", ActivatedDuration * 0.2);
	}

	UFUNCTION(NotBlueprintCallable)
	private void StopShake()
	{
		bShaking = false;
		ActorRotation = FRotator::ZeroRotator;
	}

	UFUNCTION()
	private void OnTimeLikeUpdate(float CurrentValue)
	{
		if(!HasControl())
			return;

		SyncedAlpha.Value = CurrentValue;
		SetLocationBasedOnAlpha(CurrentValue);

		if(TimeLike.Time >= 0.25 && !bCalledTurnOnEvent)
		{
			bCalledTurnOnEvent = true;
			CrumbTurnOnGrapplePoint();
		}
		
		if(TimeLike.Time >= 4.5 && !bCalledTurnOffEvent)
		{
			bCalledTurnOffEvent = true;
			CrumbTurnOffGrapplePoint();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnTimeLikeFinished()
	{
		SonarBlastTargetable.EnableForPlayer(Game::Mio, this);	
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTurnOnGrapplePoint()
	{
		PerchPointComp.EnableForPlayer(Game::Zoe, this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTurnOffGrapplePoint()
	{
		PerchPointComp.DisableForPlayer(Game::Zoe, this);
	}

	private void SetLocationBasedOnAlpha(float Alpha)
	{
		ActorLocation = Math::Lerp(OriginalLocation, TargetLocation, Alpha);
	}
}