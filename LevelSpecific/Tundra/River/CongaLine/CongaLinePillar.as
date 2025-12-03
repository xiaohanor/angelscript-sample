class ACongaLinePillar : ACongaGlowingTile
{
	access CongaWall = private, ACongaLineWall;

	UPROPERTY(NotVisible, BlueprintHidden)
	ACongaLineWall ParentWall;

	private FHazeAcceleratedVector CurrentLocation;
	FVector Origin;
	private FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		TargetLocation = ActorLocation;
		Origin = ActorLocation;
		CurrentLocation.Value = TargetLocation;
	}


	UFUNCTION(BlueprintCallable)
	void RaiseWall()
	{
		TargetLocation = Origin + FVector::UpVector * ParentWall.WallLowerAmount;
		SetDefaultColorByIndex(2);
	}

	UFUNCTION(BlueprintCallable)
	void LowerWall()
	{
		TargetLocation = Origin;
		SetActive(false);
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void SelectWall()
	{
		Editor::SelectActor(ParentWall);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float PreviousValue = BrightnessAlphaSmoothed.Value;
		Super::Tick(DeltaSeconds);

		CurrentLocation.AccelerateTo(TargetLocation, 2, DeltaSeconds);
		SetActorLocation(CurrentLocation.Value);

		if(CongaLine::GetDanceFloor() != nullptr)
		{
			if(PreviousValue < 0.99 && BrightnessAlphaSmoothed.Value >= 0.99)
			{
				FCongaTileLightUpEventParams Params;
				Params.Tile = this;
				UCongaLineManagerEventHandler::Trigger_TileLightUp(CongaLine::GetManager(), Params);
			}
			else if(PreviousValue >= 0.99 && BrightnessAlphaSmoothed.Value <= 0.99)
			{
				FCongaTileLightUpEventParams Params;
				Params.Tile = this;
				UCongaLineManagerEventHandler::Trigger_TileUnlit(CongaLine::GetManager(), Params);
			}
		}
	}
};