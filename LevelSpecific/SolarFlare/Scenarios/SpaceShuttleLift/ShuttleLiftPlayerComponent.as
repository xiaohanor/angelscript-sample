class UShuttleLiftPlayerComponent : UActorComponent
{
	AShuttleLift Lift;
	AShuttleLiftEnergyPendulum Pendulum;
	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void UpdateLiftMovement(float Amount)
	{
		// Lift.UpdateMovement(Amount);
	}
};