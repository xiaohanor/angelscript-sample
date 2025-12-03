event void FMonkeyHatchDrumEvent();

UCLASS(Abstract)
class ATundra_MonkeyHatchDrum : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRootOffset;

	UPROPERTY(DefaultComponent, Attach = MeshRootOffset)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRootOffset)
	USceneComponent UpperMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopeMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraShapeshiftingOneShotInteractionComponent TundraOneShotInteractComp;

	UPROPERTY()
	FMonkeyHatchDrumEvent OnDrumHit;

	UPROPERTY()
	FHazeTimeLike TL_MoveUp;

	UPROPERTY()
	FHazeTimeLike TL_MoveDown;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchSlamPlatform SlamPlatform;

	UPROPERTY(EditAnywhere)
	float CompletionDelay = 0.5;

	/* If true, this will never be able to be finished. Used for repeating animations over and over. */
	UPROPERTY(EditAnywhere)
	bool bDebugAnimation = false;

	bool bActive = false;
	bool bCompleted = false;
	float ActiveHeight = -40;
	bool bInteractionStarted = false;
	float TimeInteractionStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TundraOneShotInteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteract");
		TL_MoveDown.BindUpdate(this, n"TL_MoveDown_Update");
		TL_MoveDown.BindFinished(this, n"TL_MoveDown_Finished");
		TL_MoveUp.BindUpdate(this, n"TL_MoveUp_Update");
		TL_MoveUp.BindFinished(this, n"TL_MoveUp_Finished");

		TundraOneShotInteractComp.Disable(this);

		if(SlamPlatform != nullptr)
		{
			SlamPlatform.OnGroundSlammed.AddUFunction(this, n"OnPlatformSlammed");
			SlamPlatform.OnRecovered.AddUFunction(this, n"OnPlatformRecovered");
		}

		if(bDebugAnimation)
			TryActivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(TimeInteractionStarted) > CompletionDelay && !bCompleted && bInteractionStarted)
		{
			bCompleted = true;
			SlamPlatform.Disable();
			OnDrumHit.Broadcast();
			RopeMeshRoot.SetHiddenInGame(true, true);
		}
	}

	void TryActivate()
	{
		if(bActive || bCompleted)
			return;

		bActive = true;

		TL_MoveUp.PlayFromStart();
	}

	void TryDeactivate()
	{
		if(!bActive || bCompleted)
			return;

		bActive = false;

		TL_MoveDown.PlayFromStart();
		TundraOneShotInteractComp.Disable(this);
	}

	UFUNCTION()
	private void OnPlatformSlammed()
	{
		TryActivate();
	}

	UFUNCTION()
	private void OnPlatformRecovered()
	{
		if(!bDebugAnimation)
			TryDeactivate();
	}

	UFUNCTION()
	private void TL_MoveUp_Finished()
	{
		TundraOneShotInteractComp.Enable(this);
	}

	UFUNCTION()
	private void TL_MoveUp_Update(float CurrentValue)
	{
		if(bInteractionStarted)
			return;

		MeshRoot.SetRelativeLocation(FVector(0, 0, Math::Lerp(0, ActiveHeight, CurrentValue)));
		UpperMeshRoot.SetRelativeLocation(FVector(0, 0, Math::Lerp(0, -ActiveHeight, CurrentValue)));
	}

	UFUNCTION()
	private void TL_MoveDown_Finished()
	{

	}

	UFUNCTION()
	private void TL_MoveDown_Update(float CurrentValue)
	{
		if(bInteractionStarted)
			return;

		MeshRoot.SetRelativeLocation(FVector(0, 0, Math::Lerp(ActiveHeight, 0, CurrentValue)));
		UpperMeshRoot.SetRelativeLocation(FVector(0, 0, Math::Lerp(-ActiveHeight, 0, CurrentValue)));
	}

	UFUNCTION()
	private void OnInteract(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if(bDebugAnimation)
			return;

		TundraOneShotInteractComp.Disable(this);
		bInteractionStarted = true;
		TimeInteractionStarted = Time::GetGameTimeSeconds();
	}
};
