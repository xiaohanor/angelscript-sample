UCLASS(Abstract)
class UFlyingCarBazookaTargetableWidget : UTargetableWidget
{
	private float LockOnProgress;

	// How long has full lock-on been active
	UPROPERTY(BlueprintReadOnly)
	float LockedOnDuration;


	UPROPERTY(BlueprintReadOnly)
	bool bLockedOn;


	void SetLockOnProgress(float Progress)
	{
		if (Progress >= 1.0 && !bLockedOn)
		{
			bLockedOn = true;
			OnTargetAquired();
		}
		else if (LockOnProgress > 0.0 && Progress == 0.0)
		{
			bLockedOn = false;
			OnTargetLost();
		}
		else if (LockOnProgress == 0.0 && Progress > 0.0)
		{
			OnLockingStarted();
		}

		LockOnProgress = Progress;
	}


	// Has become primary target, but still need lock on
	UFUNCTION(BlueprintEvent)
	void OnLockingStarted() {}

	// Fully locked on
	UFUNCTION(BlueprintEvent)
	void OnTargetAquired() {}

	// Better luck next time :c
	UFUNCTION(BlueprintEvent)
	void OnTargetLost() {}

	// From 0 to 1, 1 being fully locked on
	UFUNCTION(BlueprintPure)
	float GetLockOnProgress()
	{
		return LockOnProgress;
	}
}