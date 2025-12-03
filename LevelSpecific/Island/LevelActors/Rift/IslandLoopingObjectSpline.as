enum EIslandLoopingObjectSplineSpawnFrequencyType
{
	Cooldown,
	Distance,
	AmountOfObjects
}

struct FIslandLoopingObjectData
{
	AHazeActor Actor;
	FSplinePosition StartSplinePosition;
	FSplinePosition SplinePosition;
	float SyncedTime = -1.0;
}

event void FIslandLoopingObjectSplineOnSpawnedEvent(AHazeActor SpawnedObject);
event void FIslandLoopingObjectSplineOnUnspawnedEvent();

class AIslandLoopingObjectSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> LoopingObjectClass;

	UPROPERTY(EditAnywhere)
	EIslandLoopingObjectSplineSpawnFrequencyType SpawnFrequencyType;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::Cooldown", EditConditionHides))
	float SpawnCooldown = 1.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::Distance", EditConditionHides))
	float DistanceBetweenObjects = 500.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::AmountOfObjects", EditConditionHides))
	int AmountOfObjects = 1;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 500.0;

	/* Set this to false if you want the objects not to move by default and manually call ActivateMovement and DeactivateMovement */
	UPROPERTY(EditAnywhere, BlueprintHidden)
	private bool bMovementActive = true;

	UPROPERTY(EditAnywhere)
	bool bAbsoluteWorldUp = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAbsoluteWorldUp", EditConditionHides))
	FVector AbsoluteWorldUp = FVector::UpVector;

	/* How long the movement will take to accelerate up to full speed */
	UPROPERTY(EditAnywhere)
	float MovementActivateDuration = 5.0;

	UPROPERTY(EditAnywhere)
	bool bReverse = false;
	
	/* If true it will spawn objects so the spline is full of objects already at BeginPlay, if false you have to wait until the first object spawned reaches the end of the spline before they are distributed */
	UPROPERTY(EditAnywhere)
	bool bPopulateSplineAtBeginPlay = true;

	/* If true the objects wont rotate at all when moving along the spline, only when they are spawned. */
	UPROPERTY(EditAnywhere)
	bool bOnlySetRotationAtSpawn = false;

	UPROPERTY(EditAnywhere)
	bool bPredictSyncLocation = false;

	UPROPERTY(EditAnywhere)
	FRotator ObjectRelativeRotation = FRotator(0.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	FVector RelativeLocation = FVector(0.0, 0.0, 0.0);

	UPROPERTY()
	FIslandLoopingObjectSplineOnSpawnedEvent OnSpawnedObject;
	UPROPERTY()
	FIslandLoopingObjectSplineOnUnspawnedEvent OnUnspawnedObject;

	private UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	private TArray<FIslandLoopingObjectData> CurrentlyLoopingObjects;
	protected FHazeAcceleratedFloat AcceleratedSpeed;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(Spline.IsClosedLoop())
		{
			AmountOfObjects = ActualAmountOfObjects;
			DistanceBetweenObjects = Spline.SplineLength / float(ActualAmountOfObjects);
			SpawnCooldown = DistanceBetweenObjects / MoveSpeed;
		}
	}

	UFUNCTION(CallInEditor)
	void CenterActorLocationOnMiddleOfSpline()
	{
		FVector OriginalLocation = Spline.WorldLocation;
		FVector CenterLocation = Spline.GetBoundsOrigin();
		ActorLocation = CenterLocation;
		Spline.WorldLocation = OriginalLocation;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(FIslandLoopingObjectData Object : CurrentlyLoopingObjects)
		{
			Object.Actor.RemoveActorDisable(n"DisableComponentFromObjectSpline");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(FIslandLoopingObjectData Object : CurrentlyLoopingObjects)
		{
			Object.Actor.AddActorDisable(n"DisableComponentFromObjectSpline");
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bMovementActive)
			AcceleratedSpeed.SnapTo(MoveSpeed);

		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(LoopingObjectClass, this);
		SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawned");

		if(HasControl() && bPopulateSplineAtBeginPlay)
		{
			float Distance = bReverse ? 0.0 : Spline.SplineLength;
			FSplinePosition SplinePos = FSplinePosition(Spline, Distance, !bReverse);

			float RemainingDistance = 0.0;
			TArray<FHazeActorSpawnParameters> SpawnBatch;
			int ObjectAmount = 0;
			while((!Spline.IsClosedLoop() && RemainingDistance == 0.0) || (Spline.IsClosedLoop() && ObjectAmount < ActualAmountOfObjects))
			{
				FHazeActorSpawnParameters Params = GetSpawnParamsFromSplinePos(SplinePos);
				SpawnBatch.Add(Params);
				SplinePos.Move(-ActualDistanceBetweenObjects, RemainingDistance);
				ObjectAmount++;
			}

			SpawnPool.SpawnBatchControl(SpawnBatch);

			if (bPredictSyncLocation)
				NetSyncInitialObjectsToTime(Time::GetActorControlCrumbTrailTime(this));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl() && LastObjectMovedDistance >= ActualDistanceBetweenObjects && (!Spline.IsClosedLoop() || CurrentlyLoopingObjects.Num() < ActualAmountOfObjects))
		{
			float Delta = Math::Abs(LastObjectMovedDistance - ActualDistanceBetweenObjects);
			float Distance = bReverse ? Spline.SplineLength - Delta : Delta;
			FSplinePosition SplinePos = FSplinePosition(Spline, Distance, !bReverse);
			SpawnObject(SplinePos);
		}

		for(int i = 0; i < CurrentlyLoopingObjects.Num(); i++)
		{
			AcceleratedSpeed.AccelerateTo(IsMovementActive() ? MoveSpeed : 0.0, MovementActivateDuration, DeltaTime);
		
			FIslandLoopingObjectData& Current = CurrentlyLoopingObjects[i];

			float RemainingDistance = 0.0;
			if (bPredictSyncLocation)
			{
				if (Current.SyncedTime != -1.0)
				{
					float ActiveTime = Time::GetActorControlCrumbTrailTime(this) - Current.SyncedTime;
					Current.SplinePosition = Current.StartSplinePosition;
					Current.SplinePosition.Move(ActiveTime * MoveSpeed, RemainingDistance);
				}
			}
			else
			{
				Current.SplinePosition.Move(AcceleratedSpeed.Value * DeltaTime, RemainingDistance);
			}

			FTransform Transform = GetObjectTransformFromSplinePosition(Current.SplinePosition);
			Current.Actor.ActorLocation = Transform.Location;
			if(bOnlySetRotationAtSpawn)
				Current.Actor.ActorRotation = SpawnRotation;
			else
				Current.Actor.ActorRotation = Transform.Rotator();
		
			if(HasControl() && RemainingDistance > 0.0)
			{
				SpawnPool.UnSpawn(Current.Actor);
				CrumbOnUnSpawn(i);
				--i;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnUnSpawn(int Index)
	{
		LocalOnUnSpawn(Index);
	}

	void LocalOnUnSpawn(int Index)
	{
		FIslandLoopingObjectData& Current = CurrentlyLoopingObjects[Index];
		Current.Actor.AddActorDisable(n"IslandLoopingObjectSpline");
		CurrentlyLoopingObjects.RemoveAt(Index);
		OnUnspawnedObject.Broadcast();
	}

	void SpawnObject(FSplinePosition SplinePos)
	{
		if(!HasControl())
			return;

		FHazeActorSpawnParameters SpawnParams = GetSpawnParamsFromSplinePos(SplinePos);
		AHazeActor SpawnedObject = SpawnPool.SpawnControl(SpawnParams);
		if (bPredictSyncLocation)
			NetSyncObjectToTime(SpawnedObject, Time::GetActorControlCrumbTrailTime(this));
	}

	UFUNCTION(NetFunction)
	private void NetSyncObjectToTime(AHazeActor SpawnedObject, float StartTime)
	{
		for (auto& Data : CurrentlyLoopingObjects)
		{
			if (Data.Actor == SpawnedObject)
			{
				Data.SyncedTime = StartTime;
				return;
			}
		}

		devError(f"Couldn't sync time for looping object {SpawnedObject}");
	}

	UFUNCTION(NetFunction)
	private void NetSyncInitialObjectsToTime(float StartTime)
	{
		for (auto& Data : CurrentlyLoopingObjects)
			Data.SyncedTime = StartTime;
	}

	FHazeActorSpawnParameters GetSpawnParamsFromSplinePos(FSplinePosition SplinePos)
	{
		FHazeActorSpawnParameters SpawnParams;
		FTransform ObjectTransform = GetObjectTransformFromSplinePosition(SplinePos);
		SpawnParams.Location = ObjectTransform.Location;
		SpawnParams.Rotation = ObjectTransform.Rotator();
		SpawnParams.Spawner = this;

		if(bOnlySetRotationAtSpawn)
		{
			SpawnParams.Rotation = SpawnRotation;
		}

		return SpawnParams;
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor Actor, FHazeActorSpawnParameters Params)
	{
		Actor.RemoveActorDisable(n"IslandLoopingObjectSpline");

		FIslandLoopingObjectData Data;
		Data.Actor = Actor;
		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Params.Location);
		Data.SplinePosition = FSplinePosition(Spline, SplineDistance, !bReverse);
		Data.StartSplinePosition = Data.SplinePosition;

		CurrentlyLoopingObjects.Add(Data);
		OnSpawnedObject.Broadcast(Actor);
	}

	UFUNCTION()
	void UnspawnAllObjects()
	{
		if(!HasControl())
			return;

		CrumbUnspawnAllObjects();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbUnspawnAllObjects()
	{
		SetActorTickEnabled(false);
		for(int i = CurrentlyLoopingObjects.Num() - 1; i >= 0; i--)
		{
			LocalOnUnSpawn(i);
		}
	}

	UFUNCTION()
	void ActivateMovement()
	{
		if(bMovementActive)
			return;

		CrumbActivateMovement();
		if (bPredictSyncLocation)
			devError("Cannot start or stop a predicted synced looping object spline");
	}

	UFUNCTION()
	void DeactivateMovement()
	{
		if(!bMovementActive)
			return;

		CrumbDeactivateMovement();
		if (bPredictSyncLocation)
			devError("Cannot start or stop a predicted synced looping object spline");
	}

	UFUNCTION(BlueprintPure)
	bool IsMovementActive()
	{
		return bMovementActive;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateMovement()
	{
		bMovementActive = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivateMovement()
	{
		bMovementActive = false;
	}

	float GetLastObjectMovedDistance() const property
	{
		float Distance = CurrentlyLoopingObjects.Last().SplinePosition.CurrentSplineDistance;
		if(bReverse)
			return Spline.SplineLength - Distance;
		
		return Distance;
	}

	float GetActualSpawnCooldown() property
	{
		return ActualDistanceBetweenObjects / MoveSpeed;
	}

	int GetActualAmountOfObjects() property
	{
		return Math::RoundToInt(Spline.SplineLength / ActualDistanceBetweenObjects);
	}

	float GetActualDistanceBetweenObjects() property
	{
		if(SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::Cooldown)
			return MoveSpeed * SpawnCooldown;
		else if(SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::Distance)
			return DistanceBetweenObjects;
		else if(SpawnFrequencyType == EIslandLoopingObjectSplineSpawnFrequencyType::AmountOfObjects)
			return Spline.SplineLength / float(AmountOfObjects);

		devError("Forgot to add case");
		return 500.0;
	}

	FTransform GetObjectTransformFromSplinePosition(FSplinePosition SplinePos) const
	{
		FVector FinalLocation = SplinePos.WorldLocation + SplinePos.WorldTransform.TransformVectorNoScale(RelativeLocation);
		FRotator Rotation = (SplinePos.WorldRotation * ObjectRelativeRotation.Quaternion()).Rotator();
		if(bAbsoluteWorldUp)
			Rotation = FRotator::MakeFromZX(AbsoluteWorldUp, Rotation.ForwardVector);
		return FTransform(Rotation, FinalLocation);
	}

	FRotator GetSpawnRotation() const property
	{
		float Distance = bReverse ? Spline.SplineLength : 0.0;
		FSplinePosition StartSplinePos = FSplinePosition(Spline, Distance, !bReverse);
		FTransform StartTransform = GetObjectTransformFromSplinePosition(StartSplinePos);
		return StartTransform.Rotator();
	}
}