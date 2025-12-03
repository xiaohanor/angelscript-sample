namespace Debug
{
	// intended to be called on tick() with new samples coming in
	UFUNCTION()
	void DrawDebugGraphOverPlayer(
		FDebugFloatHistory& GraphHistory, 
		FLinearColor Color = FLinearColor::Yellow,
		EHazeSelectPlayer OverWhichPlayer = EHazeSelectPlayer::Mio
	)
	{
		if(OverWhichPlayer == EHazeSelectPlayer::None)
			return;

		// GraphHistory = Debug::AddFloatHistorySample(NewEntry, GraphHistory);

		if(OverWhichPlayer == EHazeSelectPlayer::Mio || OverWhichPlayer == EHazeSelectPlayer::Both)
		{
			FTransform DrawTM = FTransform::Identity;
			auto Mio = Game::GetMio();
			DrawTM.Location = Mio.GetActorCenterLocation() + FVector(0.0, 0.0, 150.0);
			DrawTM.Rotation = FQuat::MakeFromX(Mio.GetViewLocation() - DrawTM.Location);
			Debug::DrawDebugFloatHistoryTransform(GraphHistory, DrawTM, FVector2D(150.0, 150.0), Color, 0.0);
		}

		if(OverWhichPlayer == EHazeSelectPlayer::Zoe || OverWhichPlayer == EHazeSelectPlayer::Both)
		{
			FTransform DrawTM = FTransform::Identity;
			auto Zoe = Game::GetZoe();
			DrawTM.Location = Zoe.GetActorCenterLocation() + FVector(0.0, 0.0, 150.0);
			DrawTM.Rotation = FQuat::MakeFromX(Zoe.GetViewLocation() - DrawTM.Location);
			Debug::DrawDebugFloatHistoryTransform(GraphHistory, DrawTM, FVector2D(150.0, 150.0), Color, 0.0);
		}
	};

	UFUNCTION()
	void DrawDebugGraphTowardsPlayerAtLocation(
		FVector Location,
		FDebugFloatHistory& GraphHistory, 
		FLinearColor Color = FLinearColor::Yellow,
		EHazeSelectPlayer TowardsWhichPlayer = EHazeSelectPlayer::Mio
	)
	{
		if(TowardsWhichPlayer == EHazeSelectPlayer::None)
			return;

		// GraphHistory = Debug::AddFloatHistorySample(NewEntry, GraphHistory);

		if(TowardsWhichPlayer == EHazeSelectPlayer::Mio || TowardsWhichPlayer == EHazeSelectPlayer::Both)
		{
			FTransform DrawTM = FTransform::Identity;
			auto Mio = Game::GetMio();
			DrawTM.Location = Location;
			DrawTM.Rotation = FQuat::MakeFromX(Mio.GetViewLocation() - DrawTM.Location);
			Debug::DrawDebugFloatHistoryTransform(GraphHistory, DrawTM, FVector2D(150.0, 150.0), Color, 0.0);
		}

		if(TowardsWhichPlayer == EHazeSelectPlayer::Zoe || TowardsWhichPlayer == EHazeSelectPlayer::Both)
		{
			FTransform DrawTM = FTransform::Identity;
			auto Zoe = Game::GetZoe();
			DrawTM.Location = Location;
			DrawTM.Rotation = FQuat::MakeFromX(Zoe.GetViewLocation() - DrawTM.Location);
			Debug::DrawDebugFloatHistoryTransform(GraphHistory, DrawTM, FVector2D(150.0, 150.0), Color, 0.0);
		}
	}
};