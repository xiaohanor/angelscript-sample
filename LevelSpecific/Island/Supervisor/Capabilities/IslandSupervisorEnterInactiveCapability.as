class UIslandSupervisorEnterInactiveCapability : UIslandSupervisorChildCapability
{
	bool bDone = false;
	FRotator OriginalRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDone = false;
		OriginalRotation = Supervisor.EyeBall.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / 1.0;
		Alpha = Math::Saturate(Alpha);
		if(Alpha == 1.0)
			bDone = true;

		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
		FQuat NewRotation = FQuat::Slerp(OriginalRotation.Quaternion(), Supervisor.ActorQuat, Alpha);
		Supervisor.SetClampedEyeRotation(NewRotation.Rotator());
	}
}