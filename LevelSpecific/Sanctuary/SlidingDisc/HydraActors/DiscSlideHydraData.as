struct FDiscSlideHydraEffectData
{
	UPROPERTY()
	AHazeNiagaraActor Effect;
	UPROPERTY()
	float AnimationActivateTime = -1.0;
	UPROPERTY()
	float AnimationDeactivateTime = -1.0;
	UPROPERTY()
	FName HydraOptionalBoneName = FName();
}

struct FDiscSlideHydraEffectEventData
{
	AHazeNiagaraActor Effect;
	float EventTime = 0.0;
	FName HydraOptionalBoneName = FName();
	bool bActivate = true;

	int opCmp(const FDiscSlideHydraEffectEventData& Other) const
	{
		if (EventTime < Other.EventTime)
			return -1;
		else if (EventTime > Other.EventTime)
			return 1;
		if (bActivate && !Other.bActivate)
			return -1;
		else if (!bActivate && Other.bActivate)
			return 1;
		return 0;
	}
}