struct FSplineUsage
{
	float LastUsedTime = -BIG_NUMBER;
	AHazeActor LastUser = nullptr;
}

class USplineUsageComponent : UActorComponent
{
	private TMap<UHazeSplineComponent, FSplineUsage> Usages;

	void Use(AHazeActor User, UHazeSplineComponent Spline)
	{
		if (User == nullptr)
			return;
		if (Spline == nullptr)
			return;

		FSplineUsage Usage;
		Usage.LastUsedTime = Time::GameTimeSeconds;
		Usage.LastUser = User;
		Usages.Add(Spline, Usage);
	}

	float GetLastUsedTime(UHazeSplineComponent Spline) const
	{	
		if (Spline == nullptr)
			return -BIG_NUMBER;

		FSplineUsage Usage;
		if (Usages.Find(Spline, Usage))
			return Usage.LastUsedTime;

		return -BIG_NUMBER;
	}
}
