
struct FActiveMoveTo
{
	UPROPERTY()
	int Id = -1;
	UPROPERTY()
	FMoveToParams Params;
	UPROPERTY()
	FMoveToDestination Destination;
	UPROPERTY()
	FOnMoveToEnded OnMoveToEnded;

	uint AddedOnFrame = 0;
};

class UMoveToComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	TArray<FActiveMoveTo> PendingMoveTos_Control;
	FActiveMoveTo ActiveMoveTo;
	int NextMoveToId = 0;

	float AnimAngleToInteractPosition;
	float AnimAngleToInteractFwd;
	float AnimDistanceToInteract;
	float AnimDuration;
	bool bAnimStartedAirborne;

	void MoveTo(FMoveToParams Params, FMoveToDestination Destination, FOnMoveToEnded OnMoveToEnded)
	{
		if (!HasControl())
			return;

		// Add new moveto
		FActiveMoveTo NewMoveTo;
		NewMoveTo.Params = Params;
		NewMoveTo.Destination = Destination;
		NewMoveTo.OnMoveToEnded = OnMoveToEnded;
		NewMoveTo.Id = NextMoveToId;
		NewMoveTo.AddedOnFrame = GFrameNumber;

		NextMoveToId++;

		PendingMoveTos_Control.Add(NewMoveTo);
		SetComponentTickEnabled(true);
	}

	bool CanActivateMoveTo(EMoveToType Type, FActiveMoveTo&out OutMoveTo)
	{
		if (PendingMoveTos_Control.Num() == 0)
			return false;

		if (PendingMoveTos_Control[0].Params.Type == Type)
		{
			OutMoveTo = PendingMoveTos_Control[0];
			return true;
		}

		return false;
	}

	bool IsMoveToActive(FActiveMoveTo MoveTo)
	{
		if (HasControl() && PendingMoveTos_Control.Num() != 0)
			return false;
		if (ActiveMoveTo.Id != MoveTo.Id)
			return false;
		return true;
	}

	bool IsAnyMoveToActive()
	{
		if (HasControl() && PendingMoveTos_Control.Num() != 0)
			return true;
		if (ActiveMoveTo.Id != -1)
			return true;
		return false;
	}

	void ActivateMoveTo(FActiveMoveTo MoveTo)
	{
		if (HasControl())
		{
			for (int i = PendingMoveTos_Control.Num() - 1; i >= 0; --i)
			{
				if (PendingMoveTos_Control[i].Id == MoveTo.Id)
					PendingMoveTos_Control.RemoveAt(i);
			}
		}

		ActiveMoveTo = MoveTo;
	}

	void FinishMoveTo(FActiveMoveTo MoveTo)
	{
		MoveTo.OnMoveToEnded.ExecuteIfBound(Cast<AHazeActor>(Owner));
		if (ActiveMoveTo.Id == MoveTo.Id)
			ActiveMoveTo = FActiveMoveTo();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		if (PendingMoveTos_Control.Num() != 0)
		{
			// Cancel the next pending moveto if it hasn't been picked up for several frames
			if (PendingMoveTos_Control[0].AddedOnFrame < GFrameNumber - 2)
			{
				CrumbCancelPendingMoveTo(PendingMoveTos_Control[0]);
			}
		}

		if (PendingMoveTos_Control.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelPendingMoveTo(FActiveMoveTo MoveTo)
	{
		ActivateMoveTo(MoveTo);
		FinishMoveTo(MoveTo);
	}
};