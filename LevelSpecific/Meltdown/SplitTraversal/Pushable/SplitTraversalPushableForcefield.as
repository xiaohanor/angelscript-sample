class ASplitTraversalPushableForcefield : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent TogglePivot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UOneShotInteractionComponent Interaction;

	bool bActive = false;
	bool bAppliedEffect = false;
	float Timer = 0.0;

	float RotateTime = 0.5;
	float Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Interaction.OnOneShotBlendingOut.AddUFunction(this, n"OnActivatePivot");
	}

	UFUNCTION()
	private void OnActivatePivot(AHazePlayerCharacter Player, UOneShotInteractionComponent InteractionComp)
	{
		bActive = true;
		Timer = 0.0;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ApplyEffect() {}

	UFUNCTION(BlueprintEvent)
	void BP_RemoveEffect() {}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		Timer += DeltaSeconds;

		float Alpha = 0.0;
		if (Timer < RotateTime)
			Alpha = Timer / RotateTime;
		else if (Timer > Duration + RotateTime)
			Alpha = Math::Saturate(1.0 - ((Timer - Duration - RotateTime) / RotateTime));
		else
			Alpha = 1.0;

		TogglePivot.SetRelativeRotation(FRotator(Alpha * 90.0, 0.0, 0.0));

		if (Timer > Duration + RotateTime * 2.0)
		{
			bActive = false;

			if (bAppliedEffect)
			{
				bAppliedEffect = false;
				BP_RemoveEffect();
			}
		}
		else if (Timer > RotateTime && !bAppliedEffect)
		{
			bAppliedEffect = true;
			BP_ApplyEffect();
		}
	}
};