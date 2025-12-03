class USpaceWalkOxygenWidget : UHazeUserWidget
{
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Enter;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation RunningOut;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation OutofAir;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation RefillAttach;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Pip1_Activate;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Pip2_Activate;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Pip3_Activate;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Pip4_Activate;
	
	private USpaceWalkOxygenPlayerComponent OxyComp;
	private int PipsActive = 4;

	private bool bTriggeredGameOver = false;
	private bool bPlayingLowWarning = false;
	private bool bExpanded = false;

	private TArray<bool> PipsHidden;
	private bool bAnimatingPip = false;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
		PipsHidden.SetNumZeroed(4);

		PlayAnimation(Enter);
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (Animation == Pip1_Activate)
			bAnimatingPip = false;
		else if (Animation == Pip2_Activate)
			bAnimatingPip = false;
		else if (Animation == Pip3_Activate)
			bAnimatingPip = false;
		else if (Animation == Pip4_Activate)
			bAnimatingPip = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Animation when running out of air
		if (!bTriggeredGameOver && OxyComp.OxygenLevel <= 0.0)
		{
			PlayAnimation(OutofAir);
			bTriggeredGameOver = true;
		}

		// Animate warning when low on oxygen
		if (OxyComp.OxygenLevel < 0.25)
		{
			if (!bPlayingLowWarning)
			{
				PlayAnimation(RunningOut, NumLoopsToPlay = 0);
				bPlayingLowWarning = true;
			}
		}
		else
		{
			if (bPlayingLowWarning)
			{
				StopAnimation(RunningOut);
				bPlayingLowWarning = false;
			}
		}

		// Animate expanding the widget when interacting with the refill tank
		if (OxyComp.OxygenInteraction != nullptr && SceneView::IsPendingFullscreen())
		{
			if (!bExpanded)
			{
				PlayAnimation(RefillAttach);
				bExpanded = true;
			}
		}
		else
		{
			if (bExpanded && !bTriggeredGameOver)
			{
				PlayAnimation(RefillAttach, PlayMode = EUMGSequencePlayMode::Reverse);
				bExpanded = false;
			}
		}

		// Add and remove pips based on oxygen level
		UpdatePip(3, OxyComp.OxygenLevel > 0.0, Pip4_Activate);
		UpdatePip(2, OxyComp.OxygenLevel > 0.25, Pip3_Activate);
		UpdatePip(1, OxyComp.OxygenLevel > 0.5, Pip2_Activate);
		UpdatePip(0, OxyComp.OxygenLevel > 0.75, Pip1_Activate);
	}

	void UpdatePip(int Index, bool bShouldBeVisible, UWidgetAnimation Animation)
	{
		if (PipsHidden[Index] == !bShouldBeVisible)
			return;
		if (bAnimatingPip)
			return;

		bAnimatingPip = true;
		PipsHidden[Index] = !bShouldBeVisible;

		if (bShouldBeVisible)
		{
			USpaceWalkOxygenEffectHandler::Trigger_OxygenPipRefilled(Player);
			PlayAnimation(Animation);
			USpaceWalkOxygenEventHandler::Trigger_OxygenPipRefilled(Player);
		}
		else
		{
			USpaceWalkOxygenEffectHandler::Trigger_OxygenPipConsumed(Player);
			PlayAnimation(Animation, PlayMode = EUMGSequencePlayMode::Reverse);
			USpaceWalkOxygenEventHandler::Trigger_OxygenPipConsumed(Player);
		}
	}
}