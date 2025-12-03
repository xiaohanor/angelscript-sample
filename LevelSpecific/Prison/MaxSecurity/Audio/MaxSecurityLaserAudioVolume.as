class AMaxSecurityLaserAudioVolume : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Yellow);
	default BrushComponent.LineThickness = 6.0;
	default BrushComponent.Mobility = EComponentMobility::Movable;

#if EDITOR	
	UFUNCTION(CallInEditor, Category = "Editor")
	void GetOverlappingLasers()
	{
		LasersInBounds.Empty();

		TArray<AMaxSecurityLaser> AllLasers = Editor::GetAllEditorWorldActorsOfClass(AMaxSecurityLaser);
		for(auto It : AllLasers)
		{
			auto Laser = Cast<AMaxSecurityLaser>(It);
			if(Laser.Level != Level)
				continue;

			if(Math::IsPointInBox(Laser.GetActorLocation(), BrushComponent.BoundsOrigin, BrushComponent.BoundsExtent))
			{
				LasersInBounds.Add(Laser);
			}
		}

		if(LasersInBounds.Num() > 0)
		{
			RootLaser = LasersInBounds[0];

			for(auto& Laser : LasersInBounds)
			{
				AMaxSecurityLaser ParentLaser = Cast<AMaxSecurityLaser>(Laser.GetAttachParentActor());
				if(ParentLaser != nullptr)
				{
					RootLaser = ParentLaser;
					break;
				}
			}
		}
		else
		{
			RootLaser = nullptr;			
		}
	}
#endif

	UPROPERTY(EditInstanceOnly)
	FSoundDefReference SoundDef;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent LoopEvent;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent MoveInEvent;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent MoveOutEvent;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent PassbyEvent;

	UPROPERTY(EditInstanceOnly)
	TArray<AMaxSecurityLaser> LasersInBounds;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaser RootLaser;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<bool> TrackPlayers;
	default TrackPlayers[0] = true;
	default TrackPlayers[1] = true;

	UPROPERTY(EditInstanceOnly)
	bool bForceUseRotation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(RootLaser != nullptr && LasersInBounds.Num() > 0 && SoundDef.SoundDef != nullptr)
		{
			RootLaser.AudioVolume = this;
			SoundDef.SpawnSoundDefAttached(RootLaser);

			// Hacky way of making sure that RootLaser has time to initialize itself
			Timer::SetTimer(this, n"LateBeginPlay", 0.1);
		}
	}

	UFUNCTION()
	void LateBeginPlay()
	{
		UMaxSecurityLaserEventHandler::Trigger_SetupLaser(RootLaser, FMaxSecurityLaserSetupParams(RootLaser));
	}

	UFUNCTION(BlueprintCallable)
	void StartOnLasersMoveIn()
	{
		UMaxSecurityLaserEventHandler::Trigger_OnLaserStartMoveIn(RootLaser, FMaxSecurityLaserSetupParams(RootLaser));
	}

	UFUNCTION(BlueprintCallable)
	void StartOnLasersMoveOut()
	{
		UMaxSecurityLaserEventHandler::Trigger_OnLaserStartMoveOut(RootLaser, FMaxSecurityLaserSetupParams(RootLaser));
	}
}