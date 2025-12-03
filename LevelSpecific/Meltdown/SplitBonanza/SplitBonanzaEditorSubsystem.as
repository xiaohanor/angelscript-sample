#if EDITOR

class USplitBonanzaEditorSubsystem : UHazeEditorSubsystem
{
	bool bHasBonanzaManager = false;

	bool bShowOtherWorlds = false;
	float ShowOtherMaxDistance = 10000;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Deinitialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		auto Manager = ASplitBonanzaManager::Get();
		bHasBonanzaManager = (Manager != nullptr);
	}

	void ShowMeshesFromOtherWorlds(ASplitBonanzaOffsetManager ClosestOffsetActor, TArray<ASplitBonanzaOffsetManager> OffsetManagers)
	{
		auto VisSubsys = UEditorVisualizationSubsystem::Get();

		FVector ViewLineStart = Editor::GetEditorViewLocation();
		FVector ViewLineDirection = Editor::GetEditorViewRotation().ForwardVector;

		for (ASplitBonanzaOffsetManager OffsetActor : OffsetManagers)
		{
			if (OffsetActor == ClosestOffsetActor)
				continue;
			if (!OffsetActor.bShowInOverlay)
				continue;

			TArray<UStaticMeshComponent> StaticMeshes;
			for (AActor Actor : OffsetActor.Level.Actors)
			{
				if (Actor == nullptr)
					continue;
				if (Actor.IsA(AGameSky))
					continue;
				if (Actor.ActorHasTag(n"DontShowInOtherWorld"))
					continue;

				StaticMeshes.Reset();
				Actor.GetComponentsByClass(StaticMeshes);

				for (auto MeshComp : StaticMeshes)
				{
					if (MeshComp.HasTag(n"DontShowInOtherWorld"))
						continue;
					FTransform MeshTransform = MeshComp.WorldTransform;
					MeshTransform.Location = MeshTransform.Location - OffsetActor.ActorLocation + ClosestOffsetActor.ActorLocation;
					FVector LocationOnViewLine = Math::ClosestPointOnInfiniteLine(ViewLineStart, ViewLineStart+ViewLineDirection, MeshTransform.Location);

					if (MeshTransform.Location.Distance(LocationOnViewLine) > ShowOtherMaxDistance + MeshComp.BoundsRadius)
						continue;

					auto VisComp = VisSubsys.DrawMesh(
						MeshComp,
						MeshTransform,
						MeshComp.StaticMesh,
					);
					VisComp.SetCastShadow(false);

					for (int i = 0, Count = MeshComp.NumMaterials; i < Count; ++i)
						VisComp.SetMaterial(i, MeshComp.GetMaterial(i));
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasBonanzaManager || Editor::IsPlaying())
			return;

		auto Overlay = GetEditorViewportOverlay();
		if (!Overlay.IsVisible())
			return;

		auto Canvas = Overlay.BeginCanvasPanel();

		auto BackgroundBox = Canvas
			.SlotAnchors(0.5, 0.0)
			.SlotAlignment(0.5, 0.0)
			.SlotOffset(0.0, -5, 0.0, 0.0)
			.SlotAutoSize(true)

			.BorderBox()
			.MinDesiredWidth(850)
			.MinDesiredHeight(30);
		;

		auto ButtonBox = BackgroundBox
			.SlotHAlign(EHorizontalAlignment::HAlign_Center)
			.HorizontalBox();

		TArray<ASplitBonanzaOffsetManager> OffsetManagers = TListedActors<ASplitBonanzaOffsetManager>().GetArray();
		OffsetManagers.Sort();

		ASplitBonanzaOffsetManager ClosestOffsetActor;
		float ClosestDist = MAX_flt;
		for (auto OffsetActor : OffsetManagers)
		{
			float Dist = OffsetActor.ActorLocation.Distance(Editor::GetEditorViewLocation());
			if (Dist < ClosestDist)
			{
				ClosestOffsetActor = OffsetActor;
				ClosestDist = Dist;
			}
		}

		int WorldIndex = 0;
		for (auto OffsetActor : OffsetManagers)
		{
			auto WorldButton = ButtonBox
				.SlotPadding(4)
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.BorderBox()
					.BackgroundColor(
							OffsetActor == ClosestOffsetActor
								? FLinearColor::Red
								: FLinearColor::Black
						)
					.SlotPadding(1)
					.BorderBox()
						.BackgroundColor(
							OffsetActor == ClosestOffsetActor
								? OffsetActor.EditorColor
								: Math::Lerp(OffsetActor.EditorColor, FLinearColor::Black, 0.7))
						.Tooltip(
							"Click to move the editor view to this level.\n"
							+ "Right click to toggle whether this level should be visible in the overlay."
						)

			;

			FString Text = OffsetActor.EditorGlyph;

			if (bShowOtherWorlds)
			{
				if (OffsetActor == ClosestOffsetActor)
					Text += " 👀";
				else if (OffsetActor.bShowInOverlay)
					Text += " ✔";
				else
					Text += " ❌";
			}

			WorldButton.SlotPadding(10)
				.Text(Text);

			if (WorldButton.WasClicked())
			{
				Editor::SetEditorViewLocation(
					Editor::GetEditorViewLocation()
						- ClosestOffsetActor.ActorLocation
						+ OffsetActor.ActorLocation
				);
			}

			if (WorldButton.WasRightClicked())
			{
				OffsetActor.bShowInOverlay = !OffsetActor.bShowInOverlay;
			}
		}

		ButtonBox.Spacer(20);
		auto ShowOtherWorldButton = ButtonBox
			.SlotPadding(0)
			.SlotVAlign(EVerticalAlignment::VAlign_Center)
			.Button("👀 Overlay")
			.Padding(10);

		if (ShowOtherWorldButton.WasClicked())
			bShowOtherWorlds = !bShowOtherWorlds;

		if (bShowOtherWorlds)
		{
			ShowMeshesFromOtherWorlds(ClosestOffsetActor, OffsetManagers);
			ShowOtherWorldButton.BackgroundColor(FLinearColor(0.22, 0.65, 0.55));
		}
	}
};

#endif