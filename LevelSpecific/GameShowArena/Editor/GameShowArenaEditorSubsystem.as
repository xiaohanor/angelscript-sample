#if EDITOR

class UGameShowArenaEditorSubsystem : UHazeEditorSubsystem
{
	bool bIsRelevant = false;
	FName SelectedPlatformLayout("");
	FName SelectedBombTossChallenge("");
	FName SelectedPlatformPosition("");

	bool bShowEditMenu;

	float MoveDelay = 0.0;
	float Increment = 0.0;
	float Duration = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		// Only activate this subsystem in levels that have this actor type in them
		if (GameShowArena::GetGameShowArenaPlatformManager() == nullptr)
		{
			bIsRelevant = false;
			return;
		}
		bIsRelevant = true;
	}

	UFUNCTION()
	void DisplayDynamicObstaclesForChallenge(EBombTossChallenges BombTossChallenge)
	{
		int ChallengeFlag = 1 << uint(BombTossChallenge);

		AGameShowArenaLaserWall FirstLaserWall; // random actor that is in bp level
		TListedActors<AGameShowArenaDynamicObstacleBase> DynamicObstacles;
		for (auto Obstacle : DynamicObstacles)
		{
			if (FirstLaserWall == nullptr && Obstacle.IsA(AGameShowArenaLaserWall))
				FirstLaserWall = Cast<AGameShowArenaLaserWall>(Obstacle);

			if (Obstacle.BombTossChallengeUses & ChallengeFlag != 0)
				Obstacle.SetIsTemporarilyHiddenInEditor(false);
			else
				Obstacle.SetIsTemporarilyHiddenInEditor(true);
		}

		TListedActors<AGameShowArenaDisplayDecalSplineFollow> SplineFollowDecals;
		for (auto Decal : SplineFollowDecals)
		{
			if (Decal.BombTossChallengeUses & ChallengeFlag != 0)
				Decal.SetIsTemporarilyHiddenInEditor(false);
			else
				Decal.SetIsTemporarilyHiddenInEditor(true);
		}

		auto ArenaLevelScriptActor = Cast<AGameShowArenaLevelScriptActor>(FirstLaserWall.GetLevelScriptActor());
		for (int i = 0; i < ArenaLevelScriptActor.GameShowArenaChallengeActors.Num(); i++)
		{
			bool bShouldHide = i != int(BombTossChallenge);
			for (auto Actor : ArenaLevelScriptActor.GameShowArenaChallengeActors[i].Actors)
			{
				if (Actor == nullptr)
					continue;

				Actor.SetIsTemporarilyHiddenInEditor(bShouldHide);
			}
		}
	}

	TArray<FName> GetChallengeOptions()
	{
		TArray<FName> ChallengeOptions;
		for (int i = 0; i < int(EBombTossChallenges::MAX); i++)
		{
			ChallengeOptions.Add(FName(f"{EBombTossChallenges(i) :n}"));
		}
		return ChallengeOptions;
	}

	TArray<FName> GetPlatformPositions()
	{
		TArray<FName> PlatformPosition;
		for (int i = 0; i < int(EBombTossPlatformPosition::MAX); i++)
		{
			PlatformPosition.Add(FName(f"{EBombTossPlatformPosition(i) :n}"));
		}
		return PlatformPosition;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Editor::IsPlaying())
			return;

		if (!bIsRelevant)
			return;

		// We can draw on the overlay to the level editor viewport for custom tooling
		auto Overlay = GetEditorViewportOverlay();
		if (!Overlay.IsVisible())
			return;

		AGameShowArenaPlatformManager PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		UGameShowArenaPlatformManagerEditorComponent EditorComp = UGameShowArenaPlatformManagerEditorComponent::Get(PlatformManager);

		auto Canvas = Overlay.BeginCanvasPanel();
		auto ButtonBarContainer = Canvas
									  .SlotAnchors(0.5, 0.0)
									  .SlotAlignment(0.5, 0.0)
									  .SlotAutoSize(true)
									  .VerticalBox();

		auto ButtonBar = ButtonBarContainer
							 .HorizontalBox();

		{
			FHazeImmediateComboBoxHandle PlatformLayoutComboBox = ButtonBar.BorderBox().MinDesiredHeight(30).ComboBox().Items(PlatformManager.GetStoredPlatformLayoutNamesAsFNames());
			PlatformLayoutComboBox.Value(FName(EditorComp.PreviewPlatformLayout));
			if (SelectedPlatformLayout != PlatformLayoutComboBox.SelectedItem)
			{
				SelectedPlatformLayout = PlatformLayoutComboBox.SelectedItem;
				EditorComp.LoadPlatformLayoutFromName(SelectedPlatformLayout);
			}
		}

		{
			auto ChallengeOptions = GetChallengeOptions();
			auto ChallengeComboBox = ButtonBar.BorderBox().MinDesiredHeight(30).ComboBox().Items(ChallengeOptions);

			if (SelectedBombTossChallenge != ChallengeComboBox.SelectedItem)
			{
				if (ChallengeComboBox.SelectedIndex > -1)
					SelectedBombTossChallenge = ChallengeComboBox.SelectedItem;
				else if (SelectedBombTossChallenge != FName(""))
					ChallengeComboBox.Value(SelectedBombTossChallenge);
				else
					ChallengeComboBox.Value(ChallengeOptions[0]);

				DisplayDynamicObstaclesForChallenge(EBombTossChallenges(ChallengeComboBox.SelectedIndex));
			}
		}

		// {
		// 	auto PlatformPositions = GetPlatformPositions();
		// 	auto PositionsComboBox = ButtonBar.BorderBox().MinDesiredHeight(30).ComboBox().Items(PlatformPositions);
		// 	if (SelectedPlatformPosition != PositionsComboBox.SelectedItem)
		// 	{
		// 		if (PositionsComboBox.SelectedIndex > -1)
		// 			SelectedPlatformPosition = PositionsComboBox.SelectedItem;
		// 		else if (SelectedPlatformPosition != FName(""))
		// 			PositionsComboBox.Value(SelectedPlatformPosition);
		// 		else
		// 			PositionsComboBox.Value(PlatformPositions[0]);

		// 		EditorComp.SetAllPlatformsToPosition(EBombTossPlatformPosition(PositionsComboBox.SelectedIndex));
		// 	}
		// }

		auto EditCheckBox = ButtonBar.BorderBox().MinDesiredHeight(30).CheckBox();
		EditCheckBox.Label("ShowPlatformEditMenu");
		bShowEditMenu = EditCheckBox.Checked(bShowEditMenu);

		if (!bShowEditMenu)
			return;

		auto EditButtonBar = ButtonBarContainer.VerticalBox();
		bool bSelectAllHiddenButtonClicked = EditButtonBar.Button("SelectAllHiddenPlatformsInLayout").WasClicked();
		if (bSelectAllHiddenButtonClicked)
		{
			TArray<AGameShowArenaPlatformArm> LayoutArms;
			for (auto Platform : TListedActors<AGameShowArenaPlatformArm>().Array)
			{
				if (Platform.LayoutMoveData.Position == EBombTossPlatformPosition::Hidden)
					LayoutArms.Add(Platform);
			}
			Editor::SelectActors(LayoutArms);
		}

		bool bSelectNonHiddenButtonClicked = EditButtonBar.Button("SelectNonHiddenPlatformsInLayout").WasClicked();
		if (bSelectNonHiddenButtonClicked)
		{
			TArray<AGameShowArenaPlatformArm> LayoutArms;
			for (auto Platform : TListedActors<AGameShowArenaPlatformArm>().Array)
			{
				if (Platform.LayoutMoveData.Position != EBombTossPlatformPosition::Hidden)
					LayoutArms.Add(Platform);
			}
			Editor::SelectActors(LayoutArms);
		}

		auto DelayInput = EditButtonBar.BorderBox().FloatInput().Label("PlatformMoveDelay");
		auto IncrementInput = EditButtonBar.FloatInput().Label("DelayIncrement");
		auto DurationInput = EditButtonBar.FloatInput().Label("PlatformMoveDuration");

		DelayInput.MinMax(0.0, 10.0);
		IncrementInput.MinMax(0.0, 10.0);
		DurationInput.MinMax(0.0, 100.0);

		MoveDelay = DelayInput.Value(MoveDelay);
		Increment = IncrementInput.Value(Increment);
		Duration = DurationInput.Value(Duration);
		float CurrentDelay = MoveDelay;
		bool bAddDelayButtonClicked = EditButtonBar.Button("AddDelayToPlatforms").WasClicked();
		if (bAddDelayButtonClicked)
		{
			for (auto Actor : Editor::GetSelectedActors())
			{
				auto Platform = Cast<ABombToss_Platform>(Actor);
				if (Platform != nullptr)
				{
					Platform.LayoutMoveData.MoveDelay = CurrentDelay;
					CurrentDelay += Increment;
				}
			}
		}
		
		bool bAddDurationButtonClicked = EditButtonBar.Button("AddMoveDurationToPlatforms").WasClicked();
		if (bAddDurationButtonClicked)
		{
			for (auto Actor : Editor::GetSelectedActors())
			{
				auto Platform = Cast<ABombToss_Platform>(Actor);
				if (Platform != nullptr)
				{
					Platform.LayoutMoveData.MoveDuration = Duration;
				}
			}
		}
		EditButtonBar.Spacer(0, 15);
		bool bSaveLayoutButtonClicked = EditButtonBar.Button("SaveLayout").WasClicked();
		if (bSaveLayoutButtonClicked)
		{
			EditorComp.SavePlatformLayout(SelectedPlatformLayout.ToString());
		}
	}
}

#endif