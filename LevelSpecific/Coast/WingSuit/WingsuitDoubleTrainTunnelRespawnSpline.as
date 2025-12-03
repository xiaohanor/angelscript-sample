UCLASS(NotBlueprintable)
class AWingsuitDoubleTrainTunnelRespawnSpline : ASplineActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere)
	float PointMoveSpeed = 6000.0;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	float TimeOfActivate = -100.0;

	UFUNCTION()
	void Activate()
	{
		TListedActors<AWingsuitManager> ListedManagers;
		if(ListedManagers.Single == nullptr)
			return;

		ListedManagers.Single.DoubleTrainTunnelRespawnSpline = this;
		TimeOfActivate = Time::GetGameTimeSeconds();

#if EDITOR
		if(bDebug)
			SetActorTickEnabled(true);
#endif
	}

	UFUNCTION()
	void Deactivate()
	{
		TListedActors<AWingsuitManager> ListedManagers;
		if(ListedManagers.Single == nullptr)
			return;

		ListedManagers.Single.DoubleTrainTunnelRespawnSpline = nullptr;

#if EDITOR
		if(bDebug)
			SetActorTickEnabled(false);
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bDebug)
			return;

		Debug::DrawDebugPoint(GetSplineRespawnPosition().WorldLocation, 20.0, FLinearColor::Red);
		Spline.DrawDebug(100, FLinearColor::Green);
	}
#endif

	FSplinePosition GetSplineRespawnPosition()
	{
		float TimeSince = Time::GetGameTimeSince(TimeOfActivate);
		return Spline.GetSplinePositionAtSplineDistance(TimeSince * PointMoveSpeed);
	}
}