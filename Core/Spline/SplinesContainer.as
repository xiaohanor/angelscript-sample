
namespace SplineContainerStatics 
{
	UHazeSplineComponent GetRandom(const TArray<UHazeSplineComponent>& Splines)
	{
		if (Splines.Num() == 0)
			return nullptr;

		int i = Math::RandRange(0, Splines.Num() - 1);
		return Splines[i];
	}

	UHazeSplineComponent GetRandomInView(const TArray<UHazeSplineComponent>& Splines, float SplineFraction)
	{
		AHazePlayerCharacter Zoe = Game::GetZoe();
		AHazePlayerCharacter Mio = Game::GetMio();
		if ((Zoe != nullptr) && (Mio != nullptr))
		{
			// Get random spline with the point at given fraction along spline in any players view
			TArray<UHazeSplineComponent> OnScreenSplines;
			for (UHazeSplineComponent Spline : Splines)
			{
				if (Spline == nullptr)
					continue;
				float Dist = Spline.SplineLength * SplineFraction;
				FVector Loc = Spline.GetWorldLocationAtSplineDistance(Dist);
				if (SceneView::IsInView(Zoe, Loc) || SceneView::IsInView(Mio, Loc))
					OnScreenSplines.Add(Spline);
			}
			if (OnScreenSplines.Num() > 0)
				return GetRandom(OnScreenSplines);
		}
		return nullptr;
	}	
}

struct FSplinesContainer
{
	private TArray<UHazeSplineComponent> Splines;
	private TArray<UHazeSplineComponent> UnusedSplines;
	private UHazeSplineComponent LastUsedSpline = nullptr;

	bool IsEmpty() const
	{
		return Splines.Num() == 0;
	}

	void Add(UHazeSplineComponent Spline)
	{
		if (Splines.Contains(Spline))
			return;
		Splines.Add(Spline);
		UnusedSplines.Add(Spline);
	}

	void Remove(UHazeSplineComponent Spline)
	{
		Splines.RemoveSingle(Spline);
		UnusedSplines.RemoveSingle(Spline);
	}

	void UpdateUsedSplines()
	{
		if (UnusedSplines.Num() == 0)
		{
			UnusedSplines = Splines; 
			if (UnusedSplines.Num() > 1)
				UnusedSplines.Remove(LastUsedSpline);
		}
	}
	void MarkSplineUsed(AHazeActor User, UHazeSplineComponent Spline)
	{
		UnusedSplines.Remove(Spline);
		LastUsedSpline = Spline;

		if ((Spline != nullptr) && (Spline.Owner != nullptr))
		{
			auto UsageComp = USplineUsageComponent::GetOrCreate(Spline.Owner);
			UsageComp.Use(User, Spline);
		}
	}

	UHazeSplineComponent UseBestSpline(AHazeActor User, float SplineFraction, float Cooldown = 0.0)
	{
		UpdateUsedSplines();
		TArray<UHazeSplineComponent> Candidates; 

		if (Cooldown > 0.0)
		{
			// Only try to use splines which hasn't been used by anyone within cooldown
			Candidates.Reserve(UnusedSplines.Num());
			for (UHazeSplineComponent Spline : UnusedSplines)
			{
				if (Spline == nullptr)
					continue;
				if (Spline.Owner == nullptr)
					continue;
				auto UsageComp = USplineUsageComponent::GetOrCreate(Spline.Owner);
				float LastUsedTime = UsageComp.GetLastUsedTime(Spline);
				if (Time::GetGameTimeSince(LastUsedTime) < Cooldown)
					continue;
				// Found spline not used by anyone for some time
				Candidates.Add(Spline);								
			}
		}
		else 
		{
			// Only care about own usage
			Candidates = UnusedSplines;			
		}

		UHazeSplineComponent Spline = SplineContainerStatics::GetRandomInView(Candidates, SplineFraction);
		if (Spline == nullptr)
			Spline = SplineContainerStatics::GetRandom(Candidates);
		if (Spline == nullptr)
			Spline = SplineContainerStatics::GetRandom(UnusedSplines); // No candidates within cooldown, allow for random backup
		MarkSplineUsed(User, Spline);
		return Spline;
	}	

	UHazeSplineComponent UseRandomSpline(AHazeActor User)
	{
		UpdateUsedSplines();
		UHazeSplineComponent Spline = SplineContainerStatics::GetRandom(UnusedSplines);
		MarkSplineUsed(User, Spline);
		return Spline;
	}
}


