event void FMonkeyHatchSlamPlatformEvent();

UCLASS(Abstract)
class ATundra_MonkeyHatchSlamPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SlamMoveRoot;

	UPROPERTY(DefaultComponent, Attach = SlamMoveRoot)
	UStaticMeshComponent SlamMeshComp;
	
	UPROPERTY(DefaultComponent, Attach = SlamMeshComp)
	UTundraGroundSlamResponseSelectorComponent GroundSlamSelectorComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComp;

	UPROPERTY()
	FMonkeyHatchSlamPlatformEvent OnGroundSlammed;
	UPROPERTY()
	FMonkeyHatchSlamPlatformEvent OnRecovered;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SlamTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RecoverTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FailedSlamTimeLike;

	UPROPERTY(EditAnywhere)
	float CooldownDuration = 5.5;

	UPROPERTY(EditDefaultsOnly)
	float SlamDepth = 190;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatches MonkeyHatch;

	float CooldownTimer = 0;
	bool bReady = true;
	float FailedSlamDepth = 50;
	bool bDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundSlamResponseComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		SlamTimeLike.BindUpdate(this, n"SlamTimeLikeUpdate");
		SlamTimeLike.BindFinished(this, n"SlamTimeLikeFinished");
		RecoverTimeLike.BindUpdate(this, n"RecoverTimeLikeUpdate");
		RecoverTimeLike.BindFinished(this, n"RecoverTimeLikeFinished");
		FailedSlamTimeLike.BindUpdate(this, n"FailedSlameTimeLikeUpdate");
	}

	UFUNCTION()
	private void FailedSlameTimeLikeUpdate(float CurrentValue)
	{
		SlamMoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(0, -FailedSlamDepth, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CooldownTimer > 0)
		{
			CooldownTimer -= DeltaSeconds;
		}

		if(CooldownTimer <= 0 && !bReady)
		{
			//TryPlatformRecover();
		}
	}

	UFUNCTION()
	private void RecoverTimeLikeFinished()
	{
		bReady = true;
		OnRecovered.Broadcast();
	}

	UFUNCTION()
	private void RecoverTimeLikeUpdate(float CurrentValue)
	{
		SlamMoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(-SlamDepth, 0, CurrentValue));
	}

	UFUNCTION()
	private void SlamTimeLikeFinished()
	{
		TryPlatformRecover();
	}

	UFUNCTION()
	private void SlamTimeLikeUpdate(float CurrentValue)
	{
		SlamMoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(0, -SlamDepth, CurrentValue));
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType,
	                          FVector PlayerLocation)
	{
		TrySlam();
	}

	UFUNCTION()
	private void TryPlatformRecover()
	{
		if(bReady || RecoverTimeLike.IsPlaying() || bDisabled)
			return;

		RecoverTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void TrySlam()
	{
		if(!bReady || bDisabled)
			return;

		if(bDisabled)
		{
			FailedSlamTimeLike.PlayFromStart();

			return;
		}

		OnGroundSlammed.Broadcast();

		CooldownTimer = CooldownDuration;

		bReady = false;

		SlamTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void Disable()
	{
		bDisabled = true;
	}
};