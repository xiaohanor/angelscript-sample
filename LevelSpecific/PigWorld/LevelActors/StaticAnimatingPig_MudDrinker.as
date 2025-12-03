
class AStaticAnimatingPig_MudDrinker : AStaticAnimatingPig
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DrinkAnim;

	UPROPERTY(EditDefaultsOnly)
	float StartDrinkTime = 0.7;

	UPROPERTY(EditDefaultsOnly)
	float StopDrinkTime = 6.6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Drink();
	}

	UFUNCTION()
	private void Drink()
	{
		PlayDrinkAnim();
	}

 	void PlayDrinkAnim()
	{
		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"Drink");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = DrinkAnim;
		AnimParams.BlendTime = 0.0;
		SkelMeshComp.PlaySlotAnimation(FHazeAnimationDelegate(), AnimFinishedDelegate, AnimParams);
		
		Timer::SetTimer(this, n"StartDrinking", StartDrinkTime);
		Timer::SetTimer(this, n"StopDrinking", StopDrinkTime);
	}

	UFUNCTION()
	private void StartDrinking()
	{
		BP_StartDrinking();
		UStaticAnimatingPig_MudDrinker_EffectEventHandler::Trigger_StartDrinking(this);
		Print("START");
	}

	UFUNCTION()
	private void StopDrinking()
	{
		BP_StopDrinking();
		UStaticAnimatingPig_MudDrinker_EffectEventHandler::Trigger_StopDrinking(this);
		Print("STOP");
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartDrinking() {}

	UFUNCTION(BlueprintEvent)
	void BP_StopDrinking() {}
}
class UStaticAnimatingPig_MudDrinker_EffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartDrinking() {}

	UFUNCTION(BlueprintEvent)
	void StopDrinking() {}
}