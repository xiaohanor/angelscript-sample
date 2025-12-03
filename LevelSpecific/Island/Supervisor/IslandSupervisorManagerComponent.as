struct FIslandSupervisorActiveForDurationData
{
	float TimeOfStartForceActive = -100.0;
	float ForceActiveDuration = -1.0;

	bool IsActive() const
	{
		if(ForceActiveDuration <= 0.0)
			return false;

		float TimeSince = Time::GetGameTimeSince(TimeOfStartForceActive);
		if(TimeSince < ForceActiveDuration)
			return true;

		return false;
	}

	void ActivateForDuration(float Duration)
	{
		TimeOfStartForceActive = Time::GetGameTimeSeconds();
		ForceActiveDuration = Duration;
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandSupervisorManagerComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeInput;

	private EIslandSupervisorMood PersistentMood = EIslandSupervisorMood::None;
	private TArray<FIslandSupervisorMoodQueueItem> MoodQueue;
	private float QueueItemStartTime = -100.0;
	private FIslandSupervisorActiveForDurationData ActiveForDurationData;
	private TArray<FInstigator> GloballyActiveInstigators;

	void SetPersistentMood(EIslandSupervisorMood Mood)
	{
		devCheck(Mood != EIslandSupervisorMood::None, "Tried to set persistent mood to None, this is not allowed!");
		MoodQueue.Reset();
		PersistentMood = Mood;
		UpdateSupervisorsEyeColor();
	}

	void ResetMood()
	{
		PersistentMood = EIslandSupervisorMood::None;
		MoodQueue.Reset();
		UpdateSupervisorsEyeColor();
	}

	void EnqueueMood(EIslandSupervisorMood Mood, float Duration)
	{
		devCheck(Mood != EIslandSupervisorMood::None, "Tried to enqueue mood None, this is not allowed!");
		devCheck(Duration > 0.0, "Tried to enqueue mood with 0 or negative duration, this is not allowed");
		FIslandSupervisorMoodQueueItem Item;
		Item.Mood = Mood;
		Item.Duration = Duration;
		if(MoodQueue.Num() == 0)
			QueueItemStartTime = Time::GetGameTimeSeconds();

		MoodQueue.Add(Item);
		PersistentMood = EIslandSupervisorMood::None;
		UpdateSupervisorsEyeColor();
	}

	EIslandSupervisorMood GetCurrentMood()
	{
		if(PersistentMood != EIslandSupervisorMood::None)
			return PersistentMood;

		if(MoodQueue.Num() == 0)
			return EIslandSupervisorMood::Neutral;

		return MoodQueue[0].Mood;
	}

	void ActivateForDuration(float Duration)
	{
		ActiveForDurationData.ActivateForDuration(Duration);
	}

	void Activate(FInstigator Instigator)
	{
		GloballyActiveInstigators.AddUnique(Instigator);
	}

	void Deactivate(FInstigator Instigator)
	{
		GloballyActiveInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsGloballyActive() const
	{
		if(ActiveForDurationData.IsActive())
			return true;

		return GloballyActiveInstigators.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ProcessMoodQueue())
		{
			UpdateSupervisorsEyeColor();
		}
	}

	void UpdateSupervisorsEyeColor()
	{
		TListedActors<AIslandSupervisor> ListedSupervisors;
		for(AIslandSupervisor Supervisor : ListedSupervisors.Array)
		{
			Supervisor.ApplyCurrentEyeColor();
		}
	}

	// Will check if the queue should progress to the next item (or has ended), if so it will return true and update the queue accordingly.
	bool ProcessMoodQueue()
	{
		bool bChanged = false;
		for(int i = 0; i < MoodQueue.Num();)
		{
			float TimeSinceQueueItemStarted = Time::GetGameTimeSince(QueueItemStartTime);
			if(TimeSinceQueueItemStarted > MoodQueue[i].Duration)
			{
				float DurationIntoNextQueueItem = TimeSinceQueueItemStarted - MoodQueue[i].Duration;
				QueueItemStartTime = Time::GetGameTimeSeconds() - DurationIntoNextQueueItem;
				MoodQueue.RemoveAt(0);
				bChanged = true;
				continue;
			}
			
			break;
		}

		return bChanged;
	}
}