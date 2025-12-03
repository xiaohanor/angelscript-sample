event void FFoundNewPathSignature();

struct FPathfollowingMoveTo
{
	UPROPERTY()
	FVector Destination;

	UPROPERTY()
	UObject Instigator;

	UPROPERTY()
	EPathfollowingPriority Priority;

	UPROPERTY()
	FOnPathfollowingMoveToDone OnDone;	

	FPathfollowingMoveTo(FVector Dest, UObject InInstigator, EPathfollowingPriority Prio, FOnPathfollowingMoveToDone DoneDelegate)
	{
		this.Instigator = InInstigator;
		this.Destination = Dest;
		this.Priority = Prio;
		this.OnDone = DoneDelegate;
	}
}

enum EPathfollowingMoveToFailReason
{
	NoPath,
	BadStart,
	BadDestination,
}

struct FNavigationPath
{
	TArray<FVector> Points;

	void Reset()
	{
		Points.Empty();
	}

	bool IsValid() const
	{
		return Points.Num() > 0;
	}

	bool IsValidPathIndex(int Index) const
	{
		return Points.IsValidIndex(Index);
	}

	void SetFromNavmeshPath(UNavigationPath NavPath)
	{
		Points = NavPath.PathPoints;
	}
}

class UPathfollowingMoveToComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UPathfollowingSettings DefaultSettings;

	FVector CurrentPathDestination;
	FNavigationPath Path;
	int PathIndex = 0;

	// Status of current MoveTo, regardless of instigator 
	EPathfollowingMoveToStatus CurrentStatus = EPathfollowingMoveToStatus::None;
	TMap<UObject, EPathfollowingMoveToStatus> FinishedStatus;

	TArray<FPathfollowingMoveTo> MoveTos;

	FFoundNewPathSignature OnFoundNewPath;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (DefaultSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DefaultSettings);
	}

	// Start moving to given destination if highest prio of current MoveTos, or queue it for movement when higher prio MoveTos are done/stopped.
	UFUNCTION()
	void MoveTo(FVector Destination, UObject Instigator, EPathfollowingPriority Prio = EPathfollowingPriority::Lowest, FOnPathfollowingMoveToDone OnDone = FOnPathfollowingMoveToDone())
	{
		UObject ScriptInstigator = Game::AllowScriptInstigator(Instigator);
		InsertMoveTo(FPathfollowingMoveTo(Destination, ScriptInstigator, Prio, OnDone));
		FinishedStatus.Add(ScriptInstigator, EPathfollowingMoveToStatus::None);
		if (CurrentStatus != EPathfollowingMoveToStatus::Moving)
			CurrentStatus = EPathfollowingMoveToStatus::Pathfinding;
	}

	private void InsertMoveTo(FPathfollowingMoveTo NewMoveTo)
	{
		// Insert sort, ascending order
		for (int i = MoveTos.Num() - 1; i >= 0; i--)
		{
			if (MoveTos[i].Instigator == NewMoveTo.Instigator)
			{
				// Just replace current one
				MoveTos[i] = NewMoveTo;
				return;
			}
			if (MoveTos[i].Priority <= NewMoveTo.Priority)
			{
				// Found an entry with higher or equal prio, insert after.
				// At same prio, latest moveto will take precedence
				MoveTos.Insert(NewMoveTo, i + 1);
				
				// Remove any other entry by same instigator
				for (int j = i - 1; j >= 0; j--)
				{
					if (MoveTos[j].Instigator == NewMoveTo.Instigator)
					{
						MoveTos.RemoveAt(j);
						return;
					}
				}
				return;
			}
		}
		// New instigator and lowest prio
		MoveTos.Insert(NewMoveTo, 0);
	}

	// Stop any ongoing move started by given instigator
	UFUNCTION()
	void StopMoveTo(UObject Instigator)
	{
		UObject ScriptInstigator = Game::AllowScriptInstigator(Instigator);
		FPathfollowingMoveTo StoppedMoveTo;		
		for (int i = MoveTos.Num() - 1; i >= 0; i--)
		{
			if (MoveTos[i].Instigator == ScriptInstigator)
			{
				StoppedMoveTo = MoveTos[i];
				MoveTos.RemoveAt(i);
				OnMoveToRemoved();
				FinishedStatus.Add(ScriptInstigator, EPathfollowingMoveToStatus::Stopped);
				break; // Only one per instigator allowed
			}
		}

		// Always safest to execute delegates as late as possible.
		// This can only be bound if instigator had an active MoveTo
		StoppedMoveTo.OnDone.ExecuteIfBound(Owner, StoppedMoveTo.Destination, ScriptInstigator, EPathfollowingMoveToStatus::Stopped);
	}

	private void OnMoveToRemoved()
	{
		// Start using next highest prio moveto if any.
		if (MoveTos.Num() > 0)
		{
			// Change destination, but leave it to path following capability 
			// to decide if pathfinding should be restarted.
			if (CurrentStatus != EPathfollowingMoveToStatus::Moving)
				CurrentStatus = EPathfollowingMoveToStatus::Pathfinding;
		}
		else
		{
			// No new destination, reset path
			ResetPath();
			CurrentStatus = EPathfollowingMoveToStatus::None;
		}
	}

	void ResetPath()
	{
		Path.Points.Empty();
		PathIndex = 0;
	}

	// Get current status for any MoveTo started by given instigator. 
	EPathfollowingMoveToStatus GetStatus(UObject Instigator) const
	{
		if (MoveTos.Num() > 0)
		{
			if (MoveTos.Last().Instigator == Instigator)
				return CurrentStatus;

			for (int i = MoveTos.Num() - 2; i >= 0; i--)
			{
				if (MoveTos[i].Instigator == Instigator)
					return EPathfollowingMoveToStatus::Queued;
			}	
		}

		// No active MoveTos with that instigator, finished status only
		EPathfollowingMoveToStatus LastStatus = EPathfollowingMoveToStatus::None;
		FinishedStatus.Find(Instigator, LastStatus);
		return LastStatus; 
	}

	void ReportComplete(bool bReachedDestination)
	{
		if (MoveTos.Num() == 0)
			return;
		
		FPathfollowingMoveTo CompletedMoveTo = MoveTos.Last();
		EPathfollowingMoveToStatus Result = (bReachedDestination ? EPathfollowingMoveToStatus::AtDestination : EPathfollowingMoveToStatus::AtFarAsWeCanGo);
		FinishedStatus.Add(CompletedMoveTo.Instigator, Result);	

		MoveTos.RemoveAt(MoveTos.Num() - 1);
		OnMoveToRemoved();

		CompletedMoveTo.OnDone.ExecuteIfBound(Owner, CompletedMoveTo.Destination, CompletedMoveTo.Instigator, Result);		
	}	

	void ReportNewPath()
	{
		OnFoundNewPath.Broadcast();
	}

	void ReportFailed(EPathfollowingMoveToFailReason Failure)
	{
		if (MoveTos.Num() == 0)
			return;

		EPathfollowingMoveToStatus Result = EPathfollowingMoveToStatus::CouldNotFindPath;
		if (Failure == EPathfollowingMoveToFailReason::BadStart)
			Result = EPathfollowingMoveToStatus::CouldNotFindStart;
		else if (Failure == EPathfollowingMoveToFailReason::BadDestination)
			Result = EPathfollowingMoveToStatus::CouldNotFindEnd;

		FPathfollowingMoveTo FailedMoveTo = MoveTos.Last();
		FinishedStatus.Add(FailedMoveTo.Instigator, Result);	

		MoveTos.RemoveAt(MoveTos.Num() - 1);
		OnMoveToRemoved();

		FailedMoveTo.OnDone.ExecuteIfBound(Owner, FailedMoveTo.Destination, FailedMoveTo.Instigator, Result);		
	}

	void ReportWaitingForPathfinding()
	{
		CurrentStatus = EPathfollowingMoveToStatus::Pathfinding;
	}

	FVector GetPathfindingDestination()
	{
		if (CurrentStatus == EPathfollowingMoveToStatus::Moving)
			return CurrentPathDestination;
		if (HasDestination() && (CurrentStatus != EPathfollowingMoveToStatus::Pathfinding)) 
			return FinalDestination; // Allow moving blindly when there's no path, might want to nuance this
		return Owner.ActorLocation;
	}

	bool HasDestination()
	{
		return (MoveTos.Num() > 0);
	}

	FVector GetFinalDestination() const property
	{
		if (!ensure(MoveTos.Num() > 0))
			return FVector(BIG_NUMBER);
		return MoveTos.Last().Destination;
	}

	bool IsMovingToFinalDestination()
	{
		if (!Path.IsValid())
			return true;
		return (PathIndex >= (Path.Points.Num() - 1));
	}

	void SetPathfindingDestination(FVector Destination)
	{
		CurrentStatus = EPathfollowingMoveToStatus::Moving;
		CurrentPathDestination = Destination;
	}

	bool WasSuccess(UObject Instigator, bool bAllowPartialPath = true)
	{
		EPathfollowingMoveToStatus Status = GetStatus(Instigator);
		switch (Status)
		{
			case EPathfollowingMoveToStatus::AtDestination:
				return true;
			case EPathfollowingMoveToStatus::AtFarAsWeCanGo:
				return bAllowPartialPath;
			default:
				return false;
		}
	}

	bool WasFailure(UObject Instigator)
	{
		EPathfollowingMoveToStatus Status = GetStatus(Instigator);
		switch (Status)
		{
			case EPathfollowingMoveToStatus::CouldNotFindEnd:
			case EPathfollowingMoveToStatus::CouldNotFindStart:
			case EPathfollowingMoveToStatus::CouldNotFindPath:
				return true;
			default:
				return false;
		}
	}

	bool IsOngoing(UObject Instigator)
	{
		EPathfollowingMoveToStatus Status = GetStatus(Instigator);
		switch (Status)
		{
			case EPathfollowingMoveToStatus::Moving:
			case EPathfollowingMoveToStatus::Pathfinding:
			case EPathfollowingMoveToStatus::Queued:
				return true;
			default:
				return false;
		}
	}
}
