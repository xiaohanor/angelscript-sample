class URedSpaceAnomalyPlayerComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	TArray<ARedSpaceAnomaly> GetAnomalies()
	{
		TListedActors<ARedSpaceAnomaly> Anomalies;
		return Anomalies.Array;
	}
}