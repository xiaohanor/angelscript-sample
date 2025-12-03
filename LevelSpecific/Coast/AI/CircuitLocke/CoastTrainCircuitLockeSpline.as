class ACoastTrainCircuitLockeSpline : ASplineActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(n"CoastTrainCircuitLockeSpline");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(n"CoastTrainCircuitLockeSpline");
	}
}