enum EIslandSupervisorMood
{
	None,
	Neutral,
	Happy,
	Angry
}

struct FIslandSupervisorMoodQueueItem
{
	EIslandSupervisorMood Mood;
	float Duration;
}