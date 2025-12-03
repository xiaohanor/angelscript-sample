#if EDITOR
class UTemporalLogEditorScrubSubsystem : UHazeEditorSubsystem
{
	TMap<FString, TSoftObjectPtr<AHazeActor>> PreviousScrubbingMeshes;
	TMap<FString, TSoftObjectPtr<AHazeActor>> ScrubbingMeshes;

	FHazeTemporalLogVisualCamera CameraValue;
	bool bScrubbingCamera = false;
	EHazePlayer ShownPlayer = EHazePlayer::Mio;

	void ScrubToFrame(UTemporalLogDevMenuConfig Config, UHazeTemporalLog TemporalLog, FString ViewingPath, int Frame)
	{
		FScopeDebugEditorWorld ScopeWorld;

		if (Editor::IsPlaying())
		{
			StopScrubbing();
			return;
		}

		if (ViewingPath.StartsWith("/Zoe"))
			ShownPlayer = EHazePlayer::Zoe;
		else if (ViewingPath.StartsWith("/Mio"))
			ShownPlayer = EHazePlayer::Mio;

		FString PlayerPath = ShownPlayer == EHazePlayer::Mio ? "/Mio" : "/Zoe";
		if (Config.bScrubCamera)
		{
			ScrubCamera(
				TemporalLog,
				PlayerPath + f"/Camera/{CameraDebug::CategoryView};Camera",
				Frame
			);
		}
		else if (bScrubbingCamera)
		{
			StopScrubbingCamera();
		}

		if (Config.bScrubAnimation)
		{
			TArray<FString> AnimationNodes;
			TemporalLog.GetAllNodesWithExtender(n"AnimationTemporalLogExtender", AnimationNodes);

			if (AnimationNodes.Num() == 0)
			{
				AnimationNodes.Add("/Mio/Animation (CharacterMesh 0)");
				AnimationNodes.Add("/Zoe/Animation (CharacterMesh 0)");
			}

			PreviousScrubbingMeshes = ScrubbingMeshes;
			ScrubbingMeshes.Reset();

			for (FString AnimNodePath : AnimationNodes)
				ScrubMesh(AnimNodePath, TemporalLog, Frame);

			// Destroy old scrubbing meshes we are no longer using
			for (auto Elem : PreviousScrubbingMeshes)
			{
				if (IsValid(Elem.Value.Get()))
					Elem.Value.Get().DestroyActor();
			}
		}
		else
		{
			if (ScrubbingMeshes.Num() != 0)
				StopScrubbingMesh();
		}
	}

	void StopScrubbing()
	{
		FScopeDebugEditorWorld ScopeWorld;
		StopScrubbingCamera();
		StopScrubbingMesh();
		RemoveEditorViewportOverlay();
	}

	void ScrubCamera(UHazeTemporalLog TemporalLog, FString ValuePath, int Frame)
	{
		bool bHasCamera = TemporalLog.GetVisualCamera(ValuePath, Frame, CameraValue);
		if (bHasCamera)
		{
			bScrubbingCamera = true;
			Editor::SetEditorViewLocation(FVector(CameraValue.Position));
			Editor::SetEditorViewRotation(FRotator(CameraValue.Rotation));
			Editor::SetEditorViewFOV(CameraValue.FieldOfView);
		}
		else
		{
			bScrubbingCamera = false;
			Editor::SetEditorViewFOV(Editor::GetEditorViewFOV());
		}
	}

	void StopScrubbingCamera()
	{
		if (!bScrubbingCamera)
			return;

		bScrubbingCamera = false;
        Editor::SetEditorViewFOV(Editor::GetEditorViewFOV());
	}

	void ScrubMesh(FString AnimationPath, UHazeTemporalLog TemporalLog, int Frame)
	{
		bool bMeshVisible = false;
		if (TemporalLog.GetBoolData(AnimationPath+"/99#Mesh;Visible", Frame, bMeshVisible))
		{
			if (!bMeshVisible)
				return;
		}

		FString ActorPath = GetTemporalLogParentPath(AnimationPath);

		FVector MeshLocation;
		if (!TemporalLog.GetWorldLocationData(ActorPath+"/Position/MeshLocation", Frame, MeshLocation))
		{
			if (!TemporalLog.GetWorldLocationData(AnimationPath+"/99#Mesh;MeshLocation", Frame, MeshLocation))
			{
				return;
			}
		}

		FRotator MeshRotation;
		if (!TemporalLog.GetRotatorData(ActorPath+"/Position/MeshRotation", Frame, MeshRotation))
		{
			if (!TemporalLog.GetRotatorData(AnimationPath+"/99#Mesh;MeshRotation", Frame, MeshRotation))
			{
				return;
			}
		}

		FVector MeshScale = FVector::OneVector;
		TemporalLog.GetVectorData(AnimationPath+"/99#Mesh;MeshScale", Frame, MeshScale);

		// If it's too far away, don't preview it
		if (MeshLocation.Distance(Editor::GetEditorViewLocation()) > 20000.0)
			return;

		UObject SkelMesh;
		if (!TemporalLog.GetObjectData(AnimationPath+"/99#Mesh;SkeletalMesh", Frame, SkelMesh, true))
		{
			auto Variant = AHazeLevelScriptActor::GetEditorPlayerVariant();
			if (AnimationPath.StartsWith("/Mio"))
				SkelMesh = Variant.MioSkeletalMesh;
			else if (AnimationPath.StartsWith("/Zoe"))
				SkelMesh = Variant.ZoeSkeletalMesh;
		}

		if (Cast<USkeletalMesh>(SkelMesh) == nullptr)
			return;

		auto MeshActor = PreviousScrubbingMeshes.FindOrAdd(AnimationPath).Get();
		if (!IsValid(MeshActor))
		{
			MeshActor = SpawnTemporaryEditorActor(AHazeActor, bHideFromSceneOutliner = false);
			MeshActor.SetActorLabel("Temporal Scrubbed Mesh: "+GetTemporalLogBaseName(ActorPath));

			auto MeshComp = UHazeEditorPreviewSkeletalMeshComponent::Create(MeshActor);
			MeshComp.SetComponentTickEnabled(false);
			MeshComp.SetHiddenInGame(false);
			MeshComp.SetVisibility(true);
			MeshComp.PreviewVisibility = EHazeEditorPreviewSkeletalMeshVisibility::AlwaysVisible;

			MeshActor.SetActorEnableCollision(false);
			ScrubbingMeshes.Add(AnimationPath, MeshActor);
		}
		else
		{
			ScrubbingMeshes.Add(AnimationPath, MeshActor);
			PreviousScrubbingMeshes.Remove(AnimationPath);
		}

		auto MeshComp = UHazeEditorPreviewSkeletalMeshComponent::Get(MeshActor);
		MeshComp.SetSkeletalMeshAsset(Cast<USkeletalMesh>(SkelMesh));

		MeshActor.SetActorLocationAndRotation(MeshLocation, MeshRotation);
		MeshActor.SetActorScale3D(MeshScale);

		UObject Animation;
		TemporalLog.GetObjectData(AnimationPath+"/2: Animations;0;Asset", Frame, Animation, true);

		UAnimationAsset AnimSeq = Cast<UAnimationAsset>(Animation);
		if (AnimSeq != nullptr)
		{
			float32 AnimPosition = 0.0;
			TemporalLog.GetFloatData(AnimationPath+"/2: Animations;0;Position", Frame, AnimPosition);

			UBlendSpace BlendSpace = Cast<UBlendSpace>(Animation);
			if (BlendSpace != nullptr)
			{
				FVector BlendSpaceInput;
				TemporalLog.GetVectorData(AnimationPath+"/2: Animations;0;Input Values", Frame, BlendSpaceInput);
				MeshComp.SetAnimationPreview(BlendSpace, AnimPosition, BlendSpacePosition = BlendSpaceInput);
			}
			else
			{
				MeshComp.SetAnimationPreview(AnimSeq, AnimPosition);
			}
		}
	}

	void StopScrubbingMesh()
	{
		for (auto Elem : ScrubbingMeshes)
		{
			if (IsValid(Elem.Value.Get()))
			{
				Elem.Value.Get().DestroyActor();
			}
		}

		ScrubbingMeshes.Reset();
	}

	void UpdateScrubbing()
	{
		FScopeDebugEditorWorld ScopeWorld;
		if (bScrubbingCamera)
		{
			if (!CameraValue.Position.Equals(FVector3f(Editor::GetEditorViewLocation()))
				|| !CameraValue.Rotation.Equals(FRotator3f(Editor::GetEditorViewRotation())))
			{
				// If we've manually changed the editor camera we stop scrubbing
				StopScrubbingCamera();
			}
			else
			{
				Editor::SetEditorViewLocation(FVector(CameraValue.Position));
				Editor::SetEditorViewRotation(FRotator(CameraValue.Rotation));
				Editor::SetEditorViewFOV(CameraValue.FieldOfView);
			}
		}

		if (ScrubbingMeshes.Num() != 0)
		{
			auto Overlay = GetEditorViewportOverlay();
			if (Overlay.IsVisible())
			{
				FLinearColor BorderColor = FLinearColor::MakeFromHex(0xff1a1a1a);

				auto Canvas = Overlay.BeginCanvasPanel();
				auto BackgroundBox = Canvas
					.SlotAnchors(0.5, 0.0)
					.SlotAlignment(0.5, 0.0)
					.SlotOffset(0.0, 10.0, 0.0, 0.0)
					.SlotAutoSize(true)
					.VerticalBox();

				BackgroundBox.SlotHAlign(EHorizontalAlignment::HAlign_Center);
				BackgroundBox.Text("WARNING:")
					.Scale(1.3)
					.Color(FLinearColor::Red)
					.ShadowColor(FLinearColor::Black)
					.ShadowOffset(FVector2D(1.0, 1.0));

				BackgroundBox.SlotHAlign(EHorizontalAlignment::HAlign_Center);
				BackgroundBox.Text("Scrubbed animation pose is approximate. Only debug animations in PIE.")
					.Scale(1.3)
					.Color(FLinearColor::Red)
					.ShadowColor(FLinearColor::Black)
					.ShadowOffset(FVector2D(1.0, 1.0));
			}
		}
	}
}
#endif