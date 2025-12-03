event void FOnRaftPlayerPaddleLeft();
event void FOnRaftPlayerPaddleRight();

class USummitRaftPaddleComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ASummitRaftPaddle> PaddleClass;

	ASummitRaftPaddle Paddle;

	access ReadOnly = private, * (readonly);

	access:ReadOnly TInstigated<ERaftPaddleAnimationState> AnimationState;

	bool bLastPaddledLeft = false;

	UPROPERTY()
	FOnRaftPlayerPaddleLeft OnPaddleLeft;

	UPROPERTY()
	FOnRaftPlayerPaddleRight OnPaddleRight;

	bool bShowTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this).Value("AnimationState", AnimationState.Get()).Value("bLastPaddledLeft", bLastPaddledLeft);
	}

	void ApplyAnimationState(ERaftPaddleAnimationState State, FInstigator Instigator, EInstigatePriority Priority)
	{
		AnimationState.Apply(State, Instigator, Priority);
	}

	void ClearAnimationStateByInstigator(FInstigator Instigator)
	{
		AnimationState.Clear(Instigator);
	}
};