event void FSanctuaryUnseenOnStartChaseSignature();
event void FSanctuaryWeeperOnStopChaseSignature();

event void FSanctuaryUnseenOnStartDarknessSignature();
event void FSanctuaryWeeperOnStopDarknessSignature();

class USanctuaryUnseenChaseComponent : UActorComponent
{
	AHazeActor HazeOwner;
	USanctuaryUnseenSettings UnseenSettings;

	private bool bInternalChasing;

	FSanctuaryUnseenOnStartChaseSignature OnStartChase;
	FSanctuaryWeeperOnStopChaseSignature OnStopChase;

	FSanctuaryUnseenOnStartDarknessSignature OnStartDarkness;
	FSanctuaryWeeperOnStopDarknessSignature OnStopDarkness;

	void SetbChasing(bool bInChasing) property
	{
		bool CurrentChasing = bInternalChasing;
		bInternalChasing = bInChasing;
		if(CurrentChasing != bInChasing)
		{
			if(bInChasing)
				OnStartChase.Broadcast();
			if(!bInChasing)
				OnStopChase.Broadcast();
		}
	}

	bool GetbChasing() property
	{
		return bInternalChasing;
	}

	private bool bInternalDarkness;

	void SetbDarkness(bool bInDarkness) property
	{
		bool CurrentDarkness = bInternalDarkness;
		bInternalDarkness = bInDarkness;
		if(CurrentDarkness != bInDarkness)
		{
			if(bInDarkness)
				OnStartDarkness.Broadcast();
			if(!bInDarkness)
				OnStopDarkness.Broadcast();
		}
	}

	bool GetbDarkness() property
	{
		return bInternalDarkness;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		UnseenSettings = USanctuaryUnseenSettings::GetSettings(HazeOwner);
		bChasing = false;
	}

	bool CanChase(AActor Target)
	{
		// TODO: Do not call every frame because HasPath is expensive
		return Pathfinding::HasPath(Owner.ActorLocation, Target.ActorLocation);
	}
}