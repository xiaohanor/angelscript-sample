enum EPlayerMovementInputCapabilityType
{
	Oval,
	Square,
};

struct FInputPlaneLock
{
	// Up/Down
	FVector UpDown = FVector::ZeroVector;
	// Left/Right
	FVector LeftRight = FVector::ZeroVector;
};

struct FMoveIntoPlayerRelativeInstigator
{
	private uint _ApplyFrame;

	void Apply(
		UPlayerMovementComponent MoveComp,
		USceneComponent RelativeTo,
		FName Socket = NAME_None,
		EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if(!IsSet() && !MoveComp.bResolveMovementLocally.Get())
		{
			MoveComp.ApplyCrumbSyncedRelativePosition(
				n"MoveIntoPlayer",
				RelativeTo,
				Socket,
				Priority
			);
		}

		_ApplyFrame = Time::FrameNumber;
	}

	void Clear(UPlayerMovementComponent MoveComp)
	{
		check(IsSet());
		_ApplyFrame = 0;

		if(!MoveComp.bResolveMovementLocally.Get())
			MoveComp.ClearCrumbSyncedRelativePosition(n"MoveIntoPlayer");
	}

	bool IsSet() const
	{
		if(_ApplyFrame == 0)
			return false;

		return true;
	}

	bool IsOld() const
	{
		check(IsSet());
		return _ApplyFrame < Time::FrameNumber;
	}
};