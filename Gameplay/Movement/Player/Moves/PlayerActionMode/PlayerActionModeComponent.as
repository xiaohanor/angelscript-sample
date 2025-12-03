namespace HazeAnimation {

	UFUNCTION()
	void AnimIncreaseActionScore(AHazePlayerCharacter Player, float Score) {
		auto ActionModeComp = UPlayerActionModeComponent::Get(Player);
		if (ActionModeComp != nullptr)
			ActionModeComp.IncreaseActionScore(Score);
	}
}

class UPlayerActionModeComponent : UActorComponent
{
	/**
	 * Component holding ActionMode values for various ABP´s that want to affect or react to the values.
	 */

	private TInstigated<EPlayerActionMode> ActionMode;
	default ActionMode.SetDefaultValue(EPlayerActionMode::AllowActionMode);

	private float ActionModeScore = 0;
	private float MaximumScore = 10;
	private float TimeSinceScoreModification = 0;

	//Have we reached our maximum score (after which we remain in ActionMode until we idle long enough for it to Decay)
	private bool CurrentlyInActionMode = false;

	//Instigated float for how long we have to wait since our last Add/Set score before we start Decaying the score
	TInstigated<float> InstigatedWaitUntilDecay;
	default InstigatedWaitUntilDecay.DefaultValue = 3;

	//Instigated bool for if we are allowed to tick down the score once the wait period is over
	TInstigated<bool> InstigatedAllowDecay;
	default InstigatedAllowDecay.DefaultValue = true;

	/**
	 * Keeping the static values for each move here for easy modification by animation
	 */

	const float StepDash_ScoreIncrease = 1;
	const float RollDash_ScoreIncrease = 1;
	const float AirDash_ScoreIncrease = 1;
	const float Jump_ScoreIncrease = 1;
	const float AirJump_ScoreIncrease = 1;

	private UPlayerHealthSettings HealthSettings;
	private bool bAppliedFromGameOverEnabled = false;
	private UPlayerInteractionsComponent PlayerInteractionsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.OnPreSequencerControl.AddUFunction(this, n"OnSequenceInitiated");
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
		PlayerInteractionsComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// If the player is near an interaction point, the automated action score is always cancelled out
		if (PlayerInteractionsComp.bIsNearInteraction && PlayerInteractionsComp.DistanceToNearestInteraction < 800.0)
			ActionModeScore = 0.0;

		// if (CurrentlyInActionMode)
		// {
			if (InstigatedAllowDecay.Get() && TimeSinceScoreModification > InstigatedWaitUntilDecay.Get())
			{
				ActionModeScore -= DeltaSeconds;
			}
			else
			{
				TimeSinceScoreModification += DeltaSeconds;
			}

			if (ActionModeScore <= 0)
			{
				ActionModeScore = 0;
				CurrentlyInActionMode = false;
			}
		// }
		
		if (HealthSettings.bGameOverWhenBothPlayersDead)
		{
			if (!bAppliedFromGameOverEnabled)
			{
				ActionMode.Apply(EPlayerActionMode::ForceActionMode, n"GameOverEnabled", EInstigatePriority::Low);
				bAppliedFromGameOverEnabled = true;
			}
		}
		else
		{
			if (bAppliedFromGameOverEnabled)
			{
				ActionMode.Clear(n"GameOverEnabled");
				bAppliedFromGameOverEnabled = false;
			}
		}
	}

	//How much should be added onto the current score (Clamped to our current maximum score)
	UFUNCTION()
	void IncreaseActionScore(float IncreaseByValue)
	{
		ActionModeScore += IncreaseByValue;
		
		if(ActionModeScore >= MaximumScore)
		{
			CurrentlyInActionMode = true;
			ActionModeScore = MaximumScore;
		}

		TimeSinceScoreModification = 0;
	}

	//Set the Current Score to specified value (Clamped to our current maximum score)
	UFUNCTION()
	void SetActionScore(float SetToValue)
	{
		if(SetToValue >= MaximumScore)
		{
			ActionModeScore = MaximumScore;
			CurrentlyInActionMode = true;
		}
		else
			ActionModeScore = SetToValue;

		TimeSinceScoreModification = 0;
	}

	//Returns the current score
	UFUNCTION()
	float GetActionScore() const property
	{
		return ActionModeScore;
	}

	//Reset Score to zero
	UFUNCTION()
	void ResetActionScore()
	{
		ActionModeScore = 0;
		CurrentlyInActionMode = false;
	}

	//Modify / set if we are currently allowed to Decay the score over time or not
	UFUNCTION()
	void ApplyAllowScoreDecrease(bool Allow, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedAllowDecay.Apply(Allow, Instigator, Priority);
	}

	//Clear any set overrides for if we are allowed to Decay the score over time
	UFUNCTION()
	void ClearAllowScoreDecrease(FInstigator Instigator)
	{
		InstigatedAllowDecay.Clear(Instigator);
	}

	//Modify / Set how long we wait until Score/Timer starts Decaying
	UFUNCTION()
	void ApplyWaitTime(float NewWaitTime, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedWaitUntilDecay.Apply(NewWaitTime, Instigator, Priority);
	}

	UFUNCTION()
	float GetCurrentWaitTime() property
	{
		return InstigatedWaitUntilDecay.Get();
	}

	//Clear any set override for how long we wait until Decay stats
	UFUNCTION()
	void ClearWaitTime(FInstigator Instigator)
	{
		InstigatedWaitUntilDecay.Clear(Instigator);
	}

	UFUNCTION()
	void OnSequenceInitiated(FHazePreSequencerControlParams Params)
	{
		ActionModeScore = 0;
		CurrentlyInActionMode = false;
	}

	UFUNCTION()
	bool GetIsCurrentlyInActionMode() const property
	{
		return CurrentlyInActionMode;
	}

	//
	EPlayerActionMode GetCurrentActionMode() const property
	{
		return ActionMode.Get();
	}

	//
	void ApplyActionMode(EPlayerActionMode Mode, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		ActionMode.Apply(Mode, Instigator, Priority);
	
		//For now dont reset ActionModeScore when we apply a force or block
		//It´s currently only reset if we enter a cutscene which involves the players	
	}

	//
	void ClearActionMode(FInstigator Instigator)
	{
		ActionMode.Clear(Instigator);
	}
};

enum EPlayerActionMode
{
	AllowActionMode,
	ForceActionMode,
	BlockActionMode
}