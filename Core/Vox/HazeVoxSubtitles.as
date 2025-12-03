
EHazeSubtitlePriority LaneToSubtitlePriority(EHazeVoxLaneName Lane)
{
	switch (Lane)
	{
		case EHazeVoxLaneName::First:
			return EHazeSubtitlePriority::High;

		case EHazeVoxLaneName::Second:
			return EHazeSubtitlePriority::Medium;

		case EHazeVoxLaneName::Generics:
		case EHazeVoxLaneName::EnemyCombat:
		case EHazeVoxLaneName::Third:
		case EHazeVoxLaneName::Efforts:
			return EHazeSubtitlePriority::Low;
	}
}

bool IsActorValid(AActor Actor)
{
	return Actor != nullptr && !Actor.IsActorBeingDestroyed();
}

class UVoxSubtitles
{
	const FName ZoeSouceTag = n"ZoeBark";
	const FName MioSouceTag = n"MioBark";
	const FName OtherSouceTag = n"NPCBark";

	private TArray<AHazePlayerCharacter> SubtitlePlayers;
	private EHazeSubtitlePriority SubtitlePriority = EHazeSubtitlePriority::Medium;
	private FHazeSubtitleLine CurrentSubtitleLine;
	private UHazeSubtitleAsset CurrentSubtitleAsset = nullptr;

// #if TEST
// 	private const int32 SubtitleMaxLen = 50;
// #endif

	UVoxSubtitles(EHazeVoxLaneName Lane)
	{
		SubtitlePriority = LaneToSubtitlePriority(Lane);
	}

	private FName FindSourceTag(AActor SpeakingActor)
	{
		if (SpeakingActor.IsA(AHazePlayerCharacter))
		{
			auto Player = Cast<AHazePlayerCharacter>(SpeakingActor);
			if (Player.IsZoe())
			{
				return ZoeSouceTag;
			}
			else if (Player.IsMio())
			{
				return MioSouceTag;
			}
		}

		return OtherSouceTag;
	}

	private void SetupPlayers()
	{
		if (SceneView::IsFullScreen())
		{
			SubtitlePlayers.Add(SceneView::GetFullScreenPlayer());
		}
		else
		{
			SubtitlePlayers.Append(Game::GetPlayers());
		}
	}

	void DisplayTextSubtitle(FText SubtitleText, AActor SpeakingActor, float MaximumDuration, TOptional<FString> TempDisplayText)
	{
		FString SubtitleStr = SubtitleText.ToString();

		// Strip out [CC] text if not enabled
		bool bCleanup = false;
		if (Console::GetConsoleVariableInt("Haze.ClosedCaptionsEnabled") == 0)
		{
			int32 StartIndex = -1;
			while (SubtitleStr.FindChar('[', StartIndex))
			{
				int32 EndIndex = -1;
				if (SubtitleStr.FindChar(']', EndIndex))
				{
					// Remove past this char
					EndIndex++;

					// Whole line is CC, skip all of it
					if (StartIndex <= 0 && EndIndex >= SubtitleStr.Len())
					{
						SubtitleStr.Reset();
						break;
					}

					SubtitleStr.RemoveAt(StartIndex, EndIndex - StartIndex);
					bCleanup = true;
				}
				else
				{
					// Missing closing bracket
					break;
				}
			}
		}
		else
		{
			// Strip out any empty [] blocks
			while (true)
			{
				int32 StartIndex = SubtitleStr.Find("[]");
				if (StartIndex < 0)
					break;

				SubtitleStr.RemoveAt(StartIndex, 2);
				bCleanup = true;
			}
		}

		// Cleanup extra spaces from line
		if (bCleanup && SubtitleStr.Len() > 0)
		{
			SubtitleStr = SubtitleStr.TrimStartAndEnd();

			int32 Index = 0;
			while (Index < SubtitleStr.Len() - 1)
			{
				if (SubtitleStr[Index] == ' ')
				{
					int32 EndIndex = Index;
					while (EndIndex < SubtitleStr.Len() - 1)
					{
						if (SubtitleStr[EndIndex + 1] != ' ')
						{
							break;
						}
						EndIndex++;
					}
					int32 RemoveCount = EndIndex - Index;
					if (RemoveCount > 0)
					{
						SubtitleStr.RemoveAt(Index, RemoveCount);
						continue;
					}
				}
				Index++;
			}
		}

		// Early out if line is empty
		if (SubtitleStr.IsEmpty())
			return;

		ClearSubtitles();

#if TEST
		const bool bDisplayAsTemp = TempDisplayText.IsSet();
		// if (SubtitleStr.Len() > SubtitleMaxLen)
		// {
		// 	FString ShortSubtitleStr = SubtitleStr.Left(SubtitleMaxLen);
		// 	ShortSubtitleStr += "**";
		// 	SubtitleStr = ShortSubtitleStr;
		// }

		if (bDisplayAsTemp)
		{
			SubtitleStr = f"[{TempDisplayText.GetValue()}] {SubtitleStr}";
		}
#endif

		CurrentSubtitleLine = FHazeSubtitleLine();
		CurrentSubtitleLine.Text = FText::FromString(SubtitleStr);
		CurrentSubtitleLine.SourceTag = FindSourceTag(SpeakingActor);
#if TEST
		CurrentSubtitleLine.bDisplayAsTemp = bDisplayAsTemp;
#else
		CurrentSubtitleLine.bDisplayAsTemp = false;
#endif

		SetupPlayers();
		for (auto Player : SubtitlePlayers)
		{
			Subtitle::ShowSubtitle(Player, CurrentSubtitleLine, 0.0, this, SubtitlePriority);
		}
	}

	void DisplayAssetSubtitle(UHazeSubtitleAsset SubtitleAsset, AActor SpeakingActor)
	{
		ClearSubtitles();

		SetupPlayers();
		CurrentSubtitleAsset = SubtitleAsset;
	}

	void ClearSubtitles()
	{
		for (AHazePlayerCharacter Player : SubtitlePlayers)
		{
			if (IsActorValid(Player))
				Subtitle::ClearSubtitlesByInstigator(Player, this);
		}
		SubtitlePlayers.Reset();
		CurrentSubtitleAsset = nullptr;
		CurrentSubtitleLine = FHazeSubtitleLine();
	}

	void Tick(float TimeInAsset)
	{
		if (CurrentSubtitleAsset != nullptr)
		{
			if (SubtitlePlayers.Num() == 1 && !SceneView::IsFullScreen())
			{
				SubtitlePlayers.Add(SubtitlePlayers[0].OtherPlayer);
			}

			for (auto Player : SubtitlePlayers)
			{
				Subtitle::ShowSubtitlesFromAsset(Player, CurrentSubtitleAsset, TimeInAsset, this, SubtitlePriority);
			}
		}
		else
		{
			if (SubtitlePlayers.Num() == 1 && !SceneView::IsFullScreen())
			{
				auto OtherPlayer = SubtitlePlayers[0].OtherPlayer;
				SubtitlePlayers.Add(OtherPlayer);
				Subtitle::ShowSubtitle(OtherPlayer, CurrentSubtitleLine, 0.0, this, SubtitlePriority);
			}
		}
	}
};
