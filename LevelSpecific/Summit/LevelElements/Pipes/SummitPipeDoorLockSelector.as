class ASummitPipeDoorLockSelector : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UAttachOwnerToParentComponent AttachToParent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(EditInstanceOnly)
	ASummitPipeDoor Door; 

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> Targets;

	int CurrentIndex = 0;

	FVector StartLocation;
	FHazeAcceleratedVector AccelVector;

	bool bMovingToTarget;
	bool bMovingToStart;

	float FallSpeed = 25.0;
	float TargetMultiplier = 2.0;
	float CurrentMultiplier;

	float HalfHeightDiff;

	bool bSoundPlaying;
	bool bPuzzleCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		AccelVector.SnapTo(StartLocation);
		HalfHeightDiff = (Targets[1].ActorLocation.Z - Targets[0].ActorLocation.Z) / 2;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPuzzleCompleted)
			return;

		if (bMovingToStart)
		{
			AccelVector.AccelerateTo(FVector(StartLocation.X, StartLocation.Y, Targets[CurrentIndex].ActorLocation.Z), 1.0, DeltaSeconds);
			
			if ((AccelVector.Value.Z - Targets[CurrentIndex].ActorLocation.Z) < 1.0)
			{
				bMovingToStart = false;
				if (bSoundPlaying)
				{
					bSoundPlaying = false;
					USummitPipeDoorLockSelectorEventHandler::Trigger_OnSelectorStopMoving(this);
				}
			}
		}
		else if (bMovingToTarget)
		{
			AccelVector.AccelerateTo(FVector(StartLocation.X, StartLocation.Y, Targets[CurrentIndex].ActorLocation.Z), 1.0, DeltaSeconds);
			
			if ((Targets[CurrentIndex].ActorLocation.Z - AccelVector.Value.Z) < 2.0)
				bMovingToTarget = false;
		}
		else if (ActorLocation.Z > Targets[0].ActorLocation.Z)
		{
			AccelVector.AccelerateTo(ActorLocation - FVector::UpVector * FallSpeed, 1.0, DeltaSeconds);
		}

		ActorLocation = AccelVector.Value;

		USummitPipeDoorLockSelectorEventHandler::Trigger_UpdateSelectorSpeed(this, FSummitPipeDoorLockSelectorUpdateParams(AccelVector.Value.Size()));
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSetTargetIndex(int TargetIndex)
	{
		if (!bSoundPlaying)
		{
			bSoundPlaying = true;
			USummitPipeDoorLockSelectorEventHandler::Trigger_OnSelectorStartMoving(this);
		}
		CurrentIndex = TargetIndex;
		bMovingToTarget = true;
	}

	void ResetTargetIndex()
	{
		CurrentIndex = 0;
		bMovingToStart = true;
		bMovingToTarget = false;
	}

	int GetCurrentIndexHeight() const
	{
		for (int i = 0; i < Targets.Num(); i++)
		{
			if (Targets[i].ActorLocation.Z + HalfHeightDiff >= AccelVector.Value.Z)
				return Math::Clamp(i, 0, 100);
		}

		return Targets.Num() - 1;
	}

	bool MovingToTarget()
	{
		return bMovingToTarget;
	}

	void CompletePuzzle()
	{
		bPuzzleCompleted = true;
		DetachRootComponentFromParent();
	}
};