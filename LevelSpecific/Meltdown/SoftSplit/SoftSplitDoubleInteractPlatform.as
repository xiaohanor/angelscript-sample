event void FOnBlendComplete();

class ASoftSplitDoubleInteractPlatform : AWorldLinkDoubleActor
{

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_ScifiTarget;
	default MeshComp_ScifiTarget.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp_ScifiTarget.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_FantasyTarget;
	default MeshComp_FantasyTarget.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp_FantasyTarget.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = MeshComp_Fantasy)
	UNiagaraComponent SplashesLeft;
	default SplashesLeft.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshComp_Fantasy)
	UNiagaraComponent SplashesRight;
	default SplashesRight.SetAutoActivate(false);

	FVector SciFiStart;
	FVector SciFiTarget;

	FVector FantasyStart;
	FVector FantasyTarget;

	UPROPERTY()
	FOnBlendComplete BlendComplete;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MovePlatform;
	default MovePlatform.Duration = 1.0;
	default MovePlatform.UseSmoothCurveZeroToOne();

	bool bLeftInteractComplete;
	bool bRightInteractComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SciFiStart = MeshComp_Scifi.RelativeLocation;
		FantasyStart = MeshComp_Fantasy.RelativeLocation;

		SciFiTarget = MeshComp_ScifiTarget.RelativeLocation;
		FantasyTarget = MeshComp_FantasyTarget.RelativeLocation;

		DoubleInteract.OnDoubleInteractionLockedIn.AddUFunction(this, n"OnLockedIn");

		DoubleInteract.PreventDoubleInteractionCompletion(this);

		MovePlatform.BindUpdate(this, n"OnUpdate");

		MovePlatform.BindFinished(this, n"OnFinished");
	}


	UFUNCTION()
	private void OnLockedIn()
	{
		Timer::SetTimer(this, n"StartMoving",0.83);
	}

	UFUNCTION()
	private void StartMoving()
	{
		MovePlatform.PlayFromStart();
		SplashesLeft.Activate();
		SplashesRight.Activate();
		BlendComplete.Broadcast();
	}

	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
		MeshComp_Scifi.SetRelativeLocation(Math::Lerp(SciFiStart,SciFiTarget, Alpha));

		MeshComp_Fantasy.SetRelativeLocation(Math::Lerp(FantasyStart,FantasyTarget,Alpha));
	}
	
	UFUNCTION(BlueprintCallable)
	void SpeedMovePlatform()
	{
		MeshComp_Scifi.SetRelativeLocation(SciFiTarget);
		MeshComp_Fantasy.SetRelativeLocation(FantasyTarget);
	}



	UFUNCTION()
	private void OnFinished()
	{
		DoubleInteract.AllowDoubleInteractionCompletion(this);
		SplashesRight.Deactivate();
		SplashesLeft.Deactivate();
	}

};