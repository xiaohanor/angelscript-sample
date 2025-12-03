UCLASS(Abstract)
class ATundra_MonkeyHatch_Door : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UBoxComponent BoxCollision;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_Open;
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_Close;
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_FailedOpen;

	bool bIsOpen = false;
	
	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchSlamPlatform SlamPlatform;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatches MonkeyHatch;

	UPROPERTY(EditDefaultsOnly)
	float MoveDistance = 220;

	float FailedMoveDistance = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TL_Open.BindUpdate(this, n"TL_OpenUpdate");
		TL_Open.BindFinished(this, n"TL_OpenFinished");
		TL_Close.BindUpdate(this, n"TL_CloseUpdate");
		TL_Close.BindFinished(this, n"TL_CloseFinished");
		TL_FailedOpen.BindUpdate(this, n"TL_FailedOpenUpdate");

		if(SlamPlatform != nullptr)
		{
			SlamPlatform.OnGroundSlammed.AddUFunction(this, n"OnPlatformSlammed");
			SlamPlatform.OnRecovered.AddUFunction(this, n"OnPlatformRecovered");
		}
	}


	UFUNCTION()
	private void TL_FailedOpenUpdate(float CurrentValue)
	{
		MoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(0, -FailedMoveDistance, CurrentValue));
	}

	UFUNCTION()
	private void OnPlatformRecovered()
	{
		if(!bIsOpen)
			return;

		TL_Close.PlayFromStart();
	}

	UFUNCTION()
	private void TL_CloseFinished()
	{
		bIsOpen = false;
	}

	UFUNCTION()
	private void TL_CloseUpdate(float CurrentValue)
	{
		MoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(-MoveDistance, 0, CurrentValue));
	}

	UFUNCTION()
	private void TL_OpenFinished()
	{
	}

	UFUNCTION()
	private void TL_OpenUpdate(float CurrentValue)
	{
		MoveRoot.RelativeLocation = FVector(0, 0, Math::Lerp(0, -MoveDistance, CurrentValue));
	}

	UFUNCTION()
	private void OnPlatformSlammed()
	{
		TryOpen();
	}

	private void TryOpen()
	{
		if(bIsOpen)
			return;

		if(MonkeyHatch != nullptr && !MonkeyHatch.bMonkeyAlerted)
		{
			TL_FailedOpen.PlayFromStart();
			return;
		}

		TL_Open.PlayFromStart();
		bIsOpen = true;
	}
};
