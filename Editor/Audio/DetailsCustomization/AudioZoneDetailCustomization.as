class UHazeAudioZoneDetails : UHazeScriptDetailCustomization
{
	default DetailClass = AHazeAudioZone;

	UHazeImmediateDrawer EditorActionsDrawer;
	UHazeImmediateDrawer ImmediateDrawer;
	AHazeAudioZone Zone;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Zone = Cast<AHazeAudioZone>(GetCustomizedObject());
		if (Zone == nullptr)
			return;
		if (Zone.World == nullptr || Zone.World.IsPreviewWorld())
			return;

		TArray<FName> DetailsToHide;
		GetHiddenCategories(DetailsToHide);
		for	(const auto& CategoryName: DetailsToHide)
		{
			HideCategory(CategoryName);
		}

		DetailsToHide.Reset();

		GetHiddenProperties(DetailsToHide);
		for	(const auto& PropertyName: DetailsToHide)
		{
			HideProperty(PropertyName);
		}

		EditCategory(n"Audio", "Audio", EScriptDetailCategoryType::Important);
		ImmediateDrawer = AddImmediateProperty(n"Audio", "Fade", true);

		EditorActionsDrawer = AddImmediateRow(n"Audio", "Editor", false);
	}

	void GetHiddenCategories(TArray<FName>& OutHiddenCategories)
	{
		if (Zone.ZoneType == EHazeAudioZoneType::Portal)
		{
			// OutHiddenCategories.Add(n"Audio");
		}
	}

	void GetHiddenProperties(TArray<FName>& OutHiddenProperties)
	{
		OutHiddenProperties.Add(n"FadeAxes");

		if (Zone.ZoneType != EHazeAudioZoneType::Ambience && Zone.ZoneType != EHazeAudioZoneType::Water)
		{
			OutHiddenProperties.Add(n"RandomSpots");
		}

		if (Zone.ZoneType != EHazeAudioZoneType::Portal)
		{
			OutHiddenProperties.Add(n"Connections");
		}

		if (Zone.ZoneType == EHazeAudioZoneType::Occlusion)
		{
			OutHiddenProperties.Add(n"ZoneAsset");
			OutHiddenProperties.Add(n"Relevance");
			OutHiddenProperties.Add(n"EnvironmentType");
		}

		if (Zone.ZoneType == EHazeAudioZoneType::Portal)
		{
			OutHiddenProperties.Add(n"ZoneAsset");
			OutHiddenProperties.Add(n"Relevance");
			OutHiddenProperties.Add(n"EnvironmentType");
			OutHiddenProperties.Add(n"Priority");
			// OutHiddenProperties.Add(n"RtpcCurve");
			OutHiddenProperties.Add(n"AttenuationLength");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Zone == nullptr)
			return;

		if (EditorActionsDrawer != nullptr && EditorActionsDrawer.IsVisible())
		{
			auto Root = EditorActionsDrawer.Begin();
			auto WaterZone = Cast<AWaterZone>(Zone);
			if (WaterZone != nullptr)
			{
				auto Box = Root.HorizontalBox();
				{
					auto ConnectSwimmingVolumes = Box
						.Button("Auto Delete/Create")
						.Tooltip("Create or deletes water zones based on YOUR choice!");

					auto FindSwimmingVolumes = Box
						.Button("Find SwimmingVolume");

					if (ConnectSwimmingVolumes)
					{
						AutoCreateOrDestroy();
					}

					if (FindSwimmingVolumes)
					{
						FindSwimmingVolumeWithInBounds();
					}
				}
			}

			EditorActionsDrawer.End();
		}

		if (ImmediateDrawer != nullptr && ImmediateDrawer.IsVisible())
		{
			auto Root = ImmediateDrawer.Begin();

			auto FadeBox = Root.HorizontalBox();
			{
				bool FadeX = FadeBox
					.CheckBox()
					.Label("X:")
					.Checked(Zone.FadeAxes.X == 1);

				bool FadeY = FadeBox
					.CheckBox()
					.Label("Y:")
					.Checked(Zone.FadeAxes.Y == 1);

				bool FadeZ = FadeBox
					.CheckBox()
					.Label("Z:")
					.Checked(Zone.FadeAxes.Z == 1);

				Zone.FadeAxes.X = FadeX ? 1 : 0;
				Zone.FadeAxes.Y = FadeY ? 1 : 0;
				Zone.FadeAxes.Z = FadeZ ? 1 : 0;
			}

			ImmediateDrawer.End();
		}

	}

	void AutoCreateOrDestroy()
	{
		auto AudioZone = Cast<AWaterZone>(GetCustomizedObject());

		#if EDITOR

		// if (AudioZone.ConnectedSwimmingVolumes.Num() == 0)
		{
			TArray<AWaterZone> WaterZones = Editor::GetAllEditorWorldActorsOfClass(AWaterZone);
			TArray<ASwimmingVolume> SwimmingVolumes = Editor::GetAllEditorWorldActorsOfClass(ASwimmingVolume);

			// Out of these zones, which are not connected to any zone?
			TSet<AActor> ConnectedSwimmingVolumes;
			TArray<AWaterZone> ZonesWithoutConnections;
			TArray<AHazePostProcessVolume> UnconnectedSwimming;

			TSet<AWaterZone> ZonesWithDeletedVolumes;

			for (auto ExistingZone: WaterZones)
			{
				auto ExistingWaterZone = Cast<AWaterZone>(ExistingZone);
				if (ExistingWaterZone.ConnectedSwimmingVolumes.Num() > 0)
				{
					for (auto ConnectedVolume: ExistingWaterZone.ConnectedSwimmingVolumes)
					{
						if (ConnectedVolume.IsNull() || ConnectedVolume.Get() == nullptr)
						{
							Warning("Found waterzone with deleted swimming volumes!");
							ZonesWithDeletedVolumes.Add(ExistingWaterZone);
							continue;
						}

						ConnectedSwimmingVolumes.Add(ConnectedVolume.Get());
					}
				}
				else
				{
					ZonesWithoutConnections.Add(ExistingWaterZone);
				}
			}

			for (auto Volume: SwimmingVolumes)
			{
				if (ConnectedSwimmingVolumes.Contains(Volume))
					continue;

				UnconnectedSwimming.Add(Cast<AHazePostProcessVolume>(Volume));
			}

			bool bAutomaticResolve = false;
			if (UnconnectedSwimming.Num() > 0)
			{
				auto Title = FText::FromString("Automatic - Creation?");
				auto Message = FText::FromString("There are unconnected swimming volumes, create and size-up for these swimming volumes?");

				if (EditorDialog::ShowMessage(Title, Message, EAppMsgType::YesNo, EAppReturnType::No) == EAppReturnType::Yes)
				{
					bAutomaticResolve = true;
				}
			}

			bool bAutomaticDeleteFind = false;
			if (ZonesWithoutConnections.Num() > 0)
			{
				auto Title = FText::FromString("Automatic - Find Or Delete?");
				auto Message = FText::FromString("There are unconnected water zones, delete those without any volume in bounds or find and size-up these swimming volumes?");

				if (EditorDialog::ShowMessage(Title, Message, EAppMsgType::YesNo, EAppReturnType::No) == EAppReturnType::Yes)
				{
					bAutomaticDeleteFind = true;
				}
			}

			TArray<AActor> UsedVolumes;
			// We update all zones first.
			for (auto ExistingZone: WaterZones)
			{
				auto ExistingWaterZone = Cast<AWaterZone>(ExistingZone);

				FBox WaterBox = FBox::BuildAABB(ExistingWaterZone.BrushComponent.BoundsOrigin, ExistingWaterZone.BrushComponent.BoundsExtent);

				int32 NumOfVolumes = ExistingWaterZone.ConnectedSwimmingVolumes.Num();
				
				for (int i = ExistingWaterZone.ConnectedSwimmingVolumes.Num()-1; i >= 0; --i)
				{
					if (ExistingWaterZone.ConnectedSwimmingVolumes[i].IsNull())
					{
						ExistingWaterZone.ConnectedSwimmingVolumes.RemoveAt(i);
					}
				}

				for	(auto Volume: SwimmingVolumes)
				{
					auto SwimmingVolume = Cast<ASwimmingVolume>(Volume);
					if (SwimmingVolume == nullptr)
						continue;

					auto VolumeBox = FBox::BuildAABB(SwimmingVolume.BrushComponent.BoundsOrigin, SwimmingVolume.BrushComponent.BoundsExtent);

					if (!(WaterBox.Intersect(VolumeBox)))
						continue;

					UnconnectedSwimming.RemoveSingle(SwimmingVolume);
					ZonesWithoutConnections.RemoveSingle(ExistingWaterZone);
					ExistingWaterZone.ConnectedSwimmingVolumes.AddUnique(SwimmingVolume);
				}

				// Agreed to delete unused water zones
				if (ExistingWaterZone.ConnectedSwimmingVolumes.Num() == 0 && bAutomaticDeleteFind)
				{
					// UNDO THIS PLX
					ExistingWaterZone.DestroyActor();
				}
				else
				{
					if (bAutomaticResolve
						&& NumOfVolumes == 0
						&& ExistingWaterZone.ConnectedSwimmingVolumes.Num() > 0)
					{
						auto FirstVolume = ExistingWaterZone.ConnectedSwimmingVolumes[0].Get();
						ExistingWaterZone.SetBrushComponentBounds(FirstVolume.BrushComponent.Bounds);
					}
				}
			}

			if (bAutomaticResolve && UnconnectedSwimming.Num() > 0)
			{
				for	(auto Volume: UnconnectedSwimming)
				{
					auto WaterActor = SpawnActor(AWaterZone, Volume.ActorLocation, Volume.ActorRotation);
					auto NewZone = Cast<AWaterZone>(WaterActor);
					auto SwimmingVolume = Cast<ASwimmingVolume>(Volume);

					NewZone.SetActorLabel("WaterZone_" + Volume.GetActorLabel());
					NewZone.ConnectedSwimmingVolumes.Add(Volume);
					NewZone.AttenuationLength = 1;

					NewZone.SetBrushComponentBounds(SwimmingVolume.BrushComponent.Bounds);
				}
			}

		}
		#endif
	}

	void FindSwimmingVolumeWithInBounds()
	{
		auto AudioZone = Cast<AWaterZone>(GetCustomizedObject());
		TArray<ASwimmingVolume> SwimmingVolumes = Editor::GetAllEditorWorldActorsOfClass(ASwimmingVolume);

		FBox WaterBox = FBox::BuildAABB(AudioZone.BrushComponent.BoundsOrigin, AudioZone.BrushComponent.BoundsExtent);

		for (int i = AudioZone.ConnectedSwimmingVolumes.Num()-1; i >= 0; --i)
		{
			if (AudioZone.ConnectedSwimmingVolumes[i].IsNull())
			{
				AudioZone.ConnectedSwimmingVolumes.RemoveAt(i);
			}
		}

		int32 NumOfVolumes = AudioZone.ConnectedSwimmingVolumes.Num();

		for	(auto Volume: SwimmingVolumes)
		{
			auto SwimmingVolume = Cast<ASwimmingVolume>(Volume);
			if (SwimmingVolume == nullptr)
				continue;

			auto VolumeBox = FBox::BuildAABB(SwimmingVolume.BrushComponent.BoundsOrigin, SwimmingVolume.BrushComponent.BoundsExtent);

			if (!(WaterBox.Intersect(VolumeBox)))
				continue;

			AudioZone.ConnectedSwimmingVolumes.AddUnique(SwimmingVolume);
		}

		if (AudioZone.ConnectedSwimmingVolumes.Num() == 0)
			return;

		auto Title = FText::FromString("Set Initial values?");
		auto Message = FText::FromString("Set Actor label and bounds of water zone?");

		if (EditorDialog::ShowMessage(Title, Message, EAppMsgType::YesNo, EAppReturnType::No) == EAppReturnType::No)
			return;

		auto FirstVolume = AudioZone.ConnectedSwimmingVolumes[0].Get();
		AudioZone.SetActorLabel("WaterZone_" + FirstVolume.GetActorLabel());
		AudioZone.AttenuationLength = 1;

		if (NumOfVolumes == 1)
		{
			AudioZone.Modify();
			AudioZone.SetActorTransform(FirstVolume.ActorTransform);
		}
	}
}