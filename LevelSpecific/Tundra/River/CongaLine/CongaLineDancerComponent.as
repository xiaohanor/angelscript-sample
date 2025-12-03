enum ECongaLineDancerState
{
	None,
	
	Idle,
	Entering,
	Dancing,
	Dispersing
}

/**
 * I chose to make the dancing functionality into a component to easily add the King also following the conga line later on.
 * Could be a special case for that too of course, and if so then this component could be moved into the Monkey actor if desired.
 */
UCLASS(NotBlueprintable)
class UCongaLineDancerComponent : UActorComponent
{
	private AHazeActor HazeOwner;
	private bool bIsEntering = false;
	private int Index = -1;
	private bool bShouldDisperse_Internal;
	bool bHasDispersed = false;
	bool bIsOnDanceFloor = false;
	float WallHitTime = -100;

	UCongaLinePlayerComponent CurrentLeader;

	ECongaLineDancerState CurrentState = ECongaLineDancerState::Idle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	void StartEnteringCongaLine()
	{
		check(CurrentLeader != nullptr);
		bIsEntering = true;
		Index = CurrentLeader.AddDancer(this);
	}

	void EnterCongaLine()
	{
		check(IsEnteringCongaLine());
		bIsEntering = false;
	}

	void ExitCongaLine(bool bInShouldDisperse)
	{
		check(IsInCongaLine() || IsEnteringCongaLine());
		CurrentLeader.RemoveDancer(this);
		bShouldDisperse = bInShouldDisperse;
		Index = -1;
	}

	UFUNCTION(CrumbFunction)
	void CrumbExitCongaLine(bool bInShouldDisperse)
	{
		if(!HasControl())
			return;

		ExitCongaLine(bInShouldDisperse);
	}

	void SetIndex(int InIndex)
	{
		check(Index >= 0);
		Index = InIndex;
	}

	bool IsEnteringCongaLine() const
	{
		return bIsEntering;
	}

	bool GetbShouldDisperse() const property
	{
		return bShouldDisperse_Internal;
	}

	void SetbShouldDisperse(bool bInShouldDisperse) property
	{
		if(!HasControl())
			return;

		bShouldDisperse_Internal = bInShouldDisperse;
	}

	bool IsInCongaLine() const
	{
		if(bIsEntering)
			return false;

		return Index >= 0;
	}

	bool IsLastDancer()
	{
		return Index == CurrentLeader.CurrentDancerCount() - 1;
	}

	bool HasHitWall()
	{
		return Time::GetGameTimeSince(WallHitTime) < CongaLine::HitWallDuration;
	}

	FTransform GetDanceTransform() const
	{
		check(Index >= 0);
		return CurrentLeader.GetTargetDanceTransform(Index);
	}
	
	FHazeRuntimeSpline CalculateNavigationPath(FVector CurrentLocation, FVector TargetLocation)
	{
		// Navigate along the nav mesh
		const UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(CurrentLocation, TargetLocation);

		if(Path == nullptr || !Path.IsValid() || Path.IsPartial())
		{
			// Found no path or only partial path, ignore navigation!
			FHazeRuntimeSpline RuntimeSpline;
			RuntimeSpline.AddPoint(CurrentLocation);
			RuntimeSpline.AddPoint(TargetLocation);
			return RuntimeSpline;
		}
		else
		{
			// Create a RuntimeSpline with the path points to smooth it out
			FHazeRuntimeSpline RuntimeSpline;
			RuntimeSpline.SetPoints(Path.PathPoints);
			return RuntimeSpline;
		}
	}
};