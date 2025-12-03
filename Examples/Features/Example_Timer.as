

/*
* Timers are set using the 'Timer' library
* Setting a timer returns a 'FTimerHandle' from where you can control the timer
*/
class AExampleTimerContainer : AActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		/*
		* Setting a timer using a function on an object
		*/
		FTimerHandle TimerHandle = Timer::SetTimer(this, n"TimerExampleFunction", 3.0);

		/*
		* Setting a timer using a delegate
		*/
		FTimerDynamicDelegate TimerDelegate;
		TimerDelegate.BindUFunction(this, n"TimerExampleFunction");
		FTimerHandle DelegateHandle = Timer::SetTimer(TimerDelegate, 3.0);

		/*
		* You can modify the timer trough the handle in various ways
		*/
		TimerHandle.PauseTimer();
		TimerHandle.UnPauseTimer();

	
		/*
		* You can also read from the timer trough the handle
		*/
		float RemainingTime = TimerHandle.GetRemainingTime();
		float ElapsedTime = TimerHandle.GetElapsedTime();
		bool bIsPaused = TimerHandle.IsTimerPaused();
		bool bIsActive = TimerHandle.IsTimerActive();


		/*
		* This will abort the timer linked to the handle
		*/
		TimerHandle.ClearTimer();

		/*
		* This will clear the connection to the Timer.
		* OBS! this will NOT clear the timer
		*/
		TimerHandle.Invalidate();

	
	
	}

	UFUNCTION()
	private void TimerExampleFunction()
	{
	}
}