enum EDragonSwordPinToGroundState
{
	None,
	Pinned,
	Exit,
};

enum EDragonSwordPinToGroundExitAnimState
{
	None,
	Standing,
	Moving
}

struct FDragonSwordPinToGroundSequenceData
{
	UPROPERTY(EditAnywhere)
	UAnimSequenceBase Sequence;

	// The duration of movementratio
	UPROPERTY(EditAnywhere)
	float Duration = 0.83;

	// The amount of units we move from movementratio
	UPROPERTY(EditAnywhere)
	float MovementLength = 100;
}

event void FDragonSwordPinToGroundOnPinningStarted(AHazePlayerCharacter Player);
event void FDragonSwordPinToGroundOnPinningStopped(AHazePlayerCharacter Player);

class UDragonSwordPinToGroundComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	float DelayBeforeAttaching = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinTimeToDisplayTutorialWhenHeld = 3;

	bool bCanAttach = false;

	float TimeOnPinnableGround = 0;

	UPROPERTY(EditAnywhere, meta = (ShowOnlyInnerProperties))
	FDragonSwordPinToGroundSequenceData ActivateSequenceData;
	default ActivateSequenceData.Duration = 0.83;
	default ActivateSequenceData.MovementLength = 100;

	UPROPERTY(EditAnywhere, meta = (ShowOnlyInnerProperties))
	FDragonSwordPinToGroundSequenceData ExitToMovingSequenceData;
	default ExitToMovingSequenceData.Duration = 0.93;
	default ExitToMovingSequenceData.MovementLength = 70;

	UPROPERTY(EditAnywhere, meta = (ShowOnlyInnerProperties))
	FDragonSwordPinToGroundSequenceData ExitSequenceData;
	default ExitSequenceData.Duration = 0.6;
	default ExitSequenceData.MovementLength = 0;

	EDragonSwordPinToGroundState State;
	EDragonSwordPinToGroundExitAnimState ExitState;

	UPROPERTY()
	FDragonSwordPinToGroundOnPinningStarted OnStartedPinningToGround;

	UPROPERTY()
	FDragonSwordPinToGroundOnPinningStopped OnStoppedPinningToGround;

	TInstigated<bool> PinnedToGround;
	bool bIsTutorialComplete = false;
	bool bIsFullyPinned = false;
	bool bIsExitFinished = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		FTemporalLog Log = TEMPORAL_LOG(this);
		Log.Value(f"State", State);
		Log.Value(f"ExitState", ExitState);
#endif
	}

	FVector GetRootMotion(UAnimSequenceBase&in Sequence, FVector& AccumulatedTranslation, float CurrentTime, float TotalMovementLength, float Duration) const
	{
		FVector RootMovement;
		const FVector TotalMoveTranslation = FVector::ForwardVector * TotalMovementLength;
		RootMovement += Sequence.GetDeltaMoveForMoveRatio(AccumulatedTranslation, CurrentTime, TotalMoveTranslation, Duration);
		return RootMovement;
	}

	const bool IsPlayerPinnedToGround() const
	{
		return PinnedToGround.Get();
	}

	void PinToGround(FInstigator Instigator, EInstigatePriority Priority)
	{
		bool bWasPinning = IsPlayerPinnedToGround();
		PinnedToGround.Apply(true, Instigator, Priority);
		if (!bWasPinning)
			OnStartedPinningToGround.Broadcast(Cast<AHazePlayerCharacter>(Owner));
	}

	void UnpinFromGround(FInstigator Instigator)
	{
		bool bWasPinning = IsPlayerPinnedToGround();
		PinnedToGround.Clear(Instigator);
		if (!bWasPinning)
			OnStoppedPinningToGround.Broadcast(Cast<AHazePlayerCharacter>(Owner));
	}
};