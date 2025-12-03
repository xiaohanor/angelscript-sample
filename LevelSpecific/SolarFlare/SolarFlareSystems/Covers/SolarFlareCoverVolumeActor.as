class ASolarFlareCoverVolumeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USolarFlareCoverOverlapComponent CoverComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterBoxComp;
	default OuterBoxComp.bGenerateOverlapEvents = true;
	default OuterBoxComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	default OuterBoxComp.SetCollisionProfileName(n"TriggerOnlyPlayer");

	void AddDisabler(FInstigator Disabler)
	{
		CoverComp.AddDisabler(Disabler);
	}

	void RemoveDisabler(FInstigator Disabler)
	{
		CoverComp.RemoveDisabler(Disabler);
	}

	bool HasDisabler(FInstigator Disabler)
	{
		return CoverComp.HasDisabler(Disabler);
	}
}