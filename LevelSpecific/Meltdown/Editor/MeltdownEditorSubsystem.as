#if EDITOR

const FConsoleCommand Command_ToggleWorldLinkOverlay("Haze.WorldLink.ToggleOverlay", n"Console_ToggleWorldLinkOverlay");
local void Console_ToggleWorldLinkOverlay(TArray<FString> Arguments)
{
	auto Subsys = UMeltdownEditorSubsystem::Get();
	Subsys.bShowOtherWorld = !Subsys.bShowOtherWorld;
}

const FConsoleCommand Command_MoveToOtherWorld("Haze.WorldLink.MoveToOtherWorld", n"Console_MoveToOtherWorld");
local void Console_MoveToOtherWorld(TArray<FString> Arguments)
{
	auto Subsys = UMeltdownEditorSubsystem::Get();
	Subsys.MoveSelectionToOtherWorld();
}

class UMeltdownEditorSubsystem : UHazePrefabEditorSubsystem
{
	bool bHasAnchors = false;
	bool bHasOverlay = false;

	bool bShowOtherWorld = false;
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
		AHazeWorldLinkAnchor MyAnchor = WorldLink::GetClosestAnchor(Editor::GetEditorViewLocation());
		bHasAnchors = (MyAnchor != nullptr);
	}

	void ShowMeshesFromOtherWorld()
	{
		TArray<AActor> EditorActors;
		EditorActors = Editor::GetAllEditorWorldActorsOfClass(AActor);

		TArray<AActor> Anchors;
		Anchors = Editor::GetAllEditorWorldActorsOfClass(AHazeWorldLinkAnchor);

		AHazeWorldLinkAnchor MyAnchor = WorldLink::GetClosestAnchor(Editor::GetEditorViewLocation());
		AHazeWorldLinkAnchor OtherAnchor = WorldLink::GetOppositeAnchor(MyAnchor);

		auto VisSubsys = UEditorVisualizationSubsystem::Get();

		FVector ViewLineStart = Editor::GetEditorViewLocation();
		FVector ViewLineDirection = Editor::GetEditorViewRotation().ForwardVector;

		TArray<UStaticMeshComponent> StaticMeshes;
		for (AActor Actor : EditorActors)
		{
			// Skip actors that are in the world we're viewing
			if (MyAnchor.GetDistanceTo(Actor) < OtherAnchor.GetDistanceTo(Actor))
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
				MeshTransform.Location = MeshTransform.Location - OtherAnchor.ActorLocation + MyAnchor.ActorLocation;
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

	void MoveSelectionToOtherWorld()
	{
		FScopedTransaction Transaction("Move Selection to Other World");

		auto EditorActorSubsystem = UEditorActorSubsystem::Get();
		auto LevelSubsystem = ULevelEditorSubsystem::Get();

		AHazeWorldLinkAnchor MyAnchor = WorldLink::GetClosestAnchor(Editor::GetEditorViewLocation());
		AHazeWorldLinkAnchor OtherAnchor = WorldLink::GetOppositeAnchor(MyAnchor);

		TArray<AActor> SelectedActors = EditorActorSubsystem.GetSelectedLevelActors();
		TArray<AActor> NewActors;
		for (auto Actor : SelectedActors)
		{
			Actor.Modify();

			FString WantedLevel = Actor.Level.Outer.Name.ToString();
			bool bWasDistinguishedLevel = false;
			if (WantedLevel.RemoveFromEnd("_Scifi"))
				bWasDistinguishedLevel = true;
			if (WantedLevel.RemoveFromEnd("_Fantasy"))
				bWasDistinguishedLevel = true;

			if (bWasDistinguishedLevel)
			{
				if (OtherAnchor.AnchorLevel == EHazeWorldLinkLevel::Fantasy)
					WantedLevel += "_Fantasy";
				else
					WantedLevel += "_Scifi";
			}

			if (Actor.Level == MyAnchor.Level && MyAnchor.Level != OtherAnchor.Level)
			{
				WantedLevel = OtherAnchor.Level.Outer.Name.ToString();
				bWasDistinguishedLevel = true;
			}

			if (bWasDistinguishedLevel && WantedLevel != Actor.Level.Outer.Name.ToString())
			{
				LevelSubsystem.SetCurrentLevelByName(FName(WantedLevel));
				auto NewActor = EditorActorSubsystem.DuplicateActor(Actor, nullptr, OtherAnchor.ActorLocation - MyAnchor.ActorLocation);
				NewActors.Add(NewActor);
				Actor.DestroyActor();
			}
			else
			{
				Actor.SetActorLocation(
					Actor.ActorLocation - MyAnchor.ActorLocation + OtherAnchor.ActorLocation
				);
				NewActors.Add(Actor);
			}
		}

		WorldLink::Editor_SetViewportShowAnchorWorld(OtherAnchor);
		EditorActorSubsystem.SetSelectedLevelActors(NewActors);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasAnchors || Editor::IsPlaying())
		{
			if (bHasOverlay)
			{
				auto Overlay = GetEditorViewportOverlay();
				if (Overlay.IsVisible())
					Overlay.Begin();
			}
			return;
		}

		auto Overlay = GetEditorViewportOverlay();
		bHasOverlay = true;

		if (!Overlay.IsVisible())
			return;

		auto Canvas = Overlay.BeginCanvasPanel();
		auto EditorActorSubsystem = UEditorActorSubsystem::Get();

		TArray<AActor> SelectedActors = EditorActorSubsystem.GetSelectedLevelActors();

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
		auto ShowOtherWorldButton = ButtonBox
			.SlotPadding(0)
			.SlotVAlign(EVerticalAlignment::VAlign_Center)
			.Button("👀 Show Other World Overlay")
			.Padding(10);

		if (ShowOtherWorldButton.WasClicked())
			bShowOtherWorld = !bShowOtherWorld;

		if (bShowOtherWorld)
		{
			ShowMeshesFromOtherWorld();
			ShowOtherWorldButton.BackgroundColor(FLinearColor(0.22, 0.65, 0.55));
		}

		auto MoveToOtherWorldButton = ButtonBox
			.SlotPadding(10, 0, 0, 0)
			.SlotVAlign(EVerticalAlignment::VAlign_Center)
			.Button("🔁 Move Selection to Other World")
			.Padding(10);

		if (SelectedActors.Num() == 0)
			MoveToOtherWorldButton.BackgroundColor(FLinearColor::Black);

		if (MoveToOtherWorldButton.WasClicked())
			MoveSelectionToOtherWorld();
	}
};

#endif