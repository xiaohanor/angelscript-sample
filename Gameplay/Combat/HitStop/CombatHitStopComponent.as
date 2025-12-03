event void FCombatHitStopSignature();

struct FActiveHitStop
{
	FInstigator Instigator;
	float UntilGameTime;
}

class UCombatHitStopComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private AHazeActor HazeOwner;
	private TArray<FActiveHitStop> HitStops;
	private TArray<AHazeActor> StoppedActors;
	private bool bIsStopped = false;
	private TArray<FInstigator> Disablers;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	void ApplyHitStop(FInstigator Instigator, float Duration)
	{
		if (IsDisabled())
			return;

		bool bExistingStop = false;
		for (FActiveHitStop& ActiveStop : HitStops)
		{
			if (ActiveStop.Instigator == Instigator)
			{
				ActiveStop.UntilGameTime = Math::Max(Time::GameTimeSeconds + Duration, ActiveStop.UntilGameTime);
				bExistingStop = true;
				break;
			}
		}

		if (!bExistingStop)
		{
			FActiveHitStop NewStop;
			NewStop.UntilGameTime = Time::GameTimeSeconds + Duration;
			NewStop.Instigator = Instigator;
			HitStops.Add(NewStop);
		}

		UpdateHitStop();
		SetComponentTickEnabled(true);
	}

	bool IsDisabled() const
	{
		return (Disablers.Num() > 0);
	}

	void Disable(FInstigator Instigator)
	{
		Disablers.AddUnique(Instigator);		
		if (bIsStopped)
			Resume();
		SetComponentTickEnabled(false);
	}

	void Enable(FInstigator Instigator)
	{
		Disablers.RemoveSingleSwap(Instigator);		
		if ((Disablers.Num() == 0) && (HitStops.Num() > 0))
			SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateHitStop();
		if (!bIsStopped && HitStops.Num() == 0)
			SetComponentTickEnabled(false);
	}

	private void UpdateHitStop()
	{
		if (!bIsStopped)
		{
			if (HitStops.Num() != 0)
				Stop();
		}
		else
		{
			if (HitStops.Num() == 0)
				Resume();
		}

		for (int i = HitStops.Num() - 1; i >= 0; --i)
		{
			if (HitStops[i].UntilGameTime <= Time::GameTimeSeconds)
				HitStops.RemoveAtSwap(i);
		}
	}

	private void Stop()
	{
		bIsStopped = true;

		TArray<AActor> Actors;
		Actors.Add(HazeOwner);
		HazeOwner.GetAttachedActors(Actors, false, true);

		for (AActor Actor : Actors)
		{
			auto HazeActor = Cast<AHazeActor>(Actor);
			if (HazeActor != nullptr)
			{
				HazeActor.SetActorTimeDilation(0.00001, this, EInstigatePriority::High);
				StoppedActors.Add(HazeActor);

#if TEST
				if (HazeActor != HazeOwner && HazeActor.IsA(AHazePlayerCharacter))
					devError("One player was attached to player during a hitstop. This causes weirdness, is the attachment wrong?");
#endif
			}
		}
	}

	private void Resume()
	{
		bIsStopped = false;

		for (AHazeActor Actor : StoppedActors)
			Actor.ClearActorTimeDilation(this);
		StoppedActors.Reset();
	}
}