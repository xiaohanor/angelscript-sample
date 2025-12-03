struct FTundra_SimonSaysStateDanceFloorWaveData
{
	access WaveCapability = private, UTundra_SimonSaysStateDanceFloorWaveCapability;

	float TileWaveDuration;
	float TileRowActivateOffset;
	float TileWaveMaxHeight;

	private bool bOverrideColor = false;
	private FLinearColor OverriddenColor = FLinearColor();

	void OverrideColor(FLinearColor Color)
	{
		bOverrideColor = true;
		OverriddenColor = Color;
	}

	access:WaveCapability
	bool IsColorOverridden(FLinearColor&out Color)
	{
		Color = OverriddenColor;
		return bOverrideColor;
	}
}

struct FTundra_SimonSaysStateDanceFloorWaveRowData
{
	TArray<ACongaDanceFloorTile> Tiles;
	float ActiveDurationStart;
}

class UTundra_SimonSaysStateDanceFloorWaveCapability : UTundra_SimonSaysStateBaseCapability
{
	default CapabilityTags.Add(n"DanceFloorWave");

	FTundra_SimonSaysStateDanceFloorWaveData CurrentData;

	float LastRowActiveDuration = 0.0;
	TArray<FTundra_SimonSaysStateDanceFloorWaveRowData> ActiveRows;
	ACongaLineDanceFloor DanceFloor;

	int CurrentRowIndex = 0;
	bool bActivate = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateDanceFloorWaveData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		if(bActivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveRows.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateDanceFloorWaveData Params)
	{
		bActivate = false;
		if(HasControl())
			CrumbActivate(Params);

		// We want to finish this state as soon as it activates because this is not a main state and should run parallel to other states!
		StateComp.StateQueue.Finish(this);

		if(HasControl())
			CurrentData = Params;
		
		Manager.SetSecondaryState(ETundra_SimonSaysState::DanceFloorWave);
		LastRowActiveDuration = -CurrentData.TileRowActivateOffset;
		CurrentRowIndex = 0;

		DanceFloor = TListedActors<ACongaLineDanceFloor>().Single;
		DanceFloor.SetDiscoModeActive(false);

		UTundra_SimonSaysManagerEffectHandler::Trigger_OnTileWave(Manager);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void OnDeactivated()
	{
		Manager.SetSecondaryState(ETundra_SimonSaysState::None);

		for(int i = ActiveRows.Num() - 1; i >= 0; i--)
		{
			FTundra_SimonSaysStateDanceFloorWaveRowData RowData = ActiveRows[i];

			for(ACongaDanceFloorTile Tile : RowData.Tiles)
			{
				Tile.ResetLocationToOriginal();
				Tile.Disable(this);
				Tile.ClearColorOverride(this);
				Manager.EndTileMove(Tile, this);
			}
		}
		ActiveRows.Reset();
		DanceFloor.SetDiscoModeActive(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TryAddNewRow();
		HandleMoveRows();
	}

	void TryAddNewRow()
	{
		if(CurrentRowIndex >= DanceFloor.Height)
			return;

		if(ActiveDuration - LastRowActiveDuration < CurrentData.TileRowActivateOffset)
			return;

		FTundra_SimonSaysStateDanceFloorWaveRowData RowData;
		RowData.ActiveDurationStart = ActiveDuration;
		int StartIndex = DanceFloor.Height - CurrentRowIndex - 1;

		for(int i = 0; i < DanceFloor.Width; i++)
		{
			int CurrentIndex = StartIndex + i * DanceFloor.Height;
			ACongaDanceFloorTile Tile = DanceFloor.Tiles[CurrentIndex];
			if(Manager.IsUpTile(Tile))
				continue;

			FLinearColor Color;
			if(CurrentData.IsColorOverridden(Color))
				Tile.ApplyColorOverride(Color, this, EInstigatePriority::Override);

			Tile.Enable(this);
			RowData.Tiles.Add(Tile);
			Manager.PrepareTileMove(Tile, this);
		}

		ActiveRows.Add(RowData);
		
		LastRowActiveDuration += CurrentData.TileRowActivateOffset;
		CurrentRowIndex++;
	}

	void HandleMoveRows()
	{
		for(int i = ActiveRows.Num() - 1; i >= 0; i--)
		{
			FTundra_SimonSaysStateDanceFloorWaveRowData RowData = ActiveRows[i];

			float Alpha = Math::Saturate((ActiveDuration - RowData.ActiveDurationStart) / CurrentData.TileWaveDuration);
			bool bDone = Alpha == 1.0;
			float SinAlpha = Math::Sin(Alpha * PI);
			FVector Offset = FVector::UpVector * (CurrentData.TileWaveMaxHeight * SinAlpha);

			for(ACongaDanceFloorTile Tile : RowData.Tiles)
			{
				if(bDone)
				{
					Tile.ResetLocationToOriginal();
					Tile.Disable(this);
					Tile.ClearColorOverride(this);
					Manager.EndTileMove(Tile, this);
					continue;
				}

				FVector TileLocation = Tile.GetOriginalLocation() + Offset;
				Tile.ActorLocation = TileLocation;
			}
			
			if(bDone)
			{
				ActiveRows.RemoveAt(i);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate(FTundra_SimonSaysStateDanceFloorWaveData Data)
	{
		if(HasControl())
			return;

		CurrentData = Data;
		bActivate = true;
	}
}