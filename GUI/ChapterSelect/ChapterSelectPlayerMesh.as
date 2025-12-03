class AChapterSelectPlayerMesh : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent MeshA;
	default MeshA.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	default MeshA.SetLightingChannels(false, false, true);

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent MeshB;
	default MeshB.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	default MeshB.SetLightingChannels(false, false, true);
	default MeshB.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UPostProcessComponent SketchbookPostProcess;
	default SketchbookPostProcess.bEnabled = false;
	default SketchbookPostProcess.bUnbound = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ADentistGooglyEye> GooglyEyeClass;

	UPROPERTY(EditAnywhere)
	UMaterialInterface SketchbookEyeMaterial;
	UPROPERTY(EditAnywhere)
	int SketchbookEyeMaterialIndex = 6;

	const float TransitionDuration = 0.5;

	bool bTransitionActive = false;
	bool bTransitioningToB = true;
	float TransitionTimer = 0.0;

	USkeletalMesh ActiveMesh;
	UAnimSequence ActiveAnimation;

	USkeletalMesh PendingMesh;
	UAnimSequence PendingAnimation;

	TArray<ADentistGooglyEye> GooglyEyes;
	bool bWantPostProcess = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshB.SetLeaderPoseComponent(MeshA);
	}

	void TransitionToMesh(USkeletalMesh MeshAsset, UAnimSequence Animation)
	{
		if (MeshAsset == ActiveMesh && Animation == ActiveAnimation)
			return;

		if (ActiveAnimation != Animation)
		{
			// If the animation changes, snap instead of doing a blend
			MeshA.SetSkeletalMeshAsset(MeshAsset);
			for (int i = 0, Count = MeshA.NumMaterials; i < Count; ++i)
				MeshA.SetMaterial(i, MeshA.SkeletalMeshAsset.Materials[i].MaterialInterface);

			MeshA.ResetAllAnimation();

			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = Animation;
			AnimParams.bLoop = true;
			MeshA.PlaySlotAnimation(AnimParams);

			MeshA.SetHiddenInGame(false);

			MeshB.SetSkeletalMeshAsset(MeshAsset);
			for (int i = 0, Count = MeshB.NumMaterials; i < Count; ++i)
				MeshB.SetMaterial(i, MeshB.SkeletalMeshAsset.Materials[i].MaterialInterface);
			MeshB.SetHiddenInGame(true);

			UpdateMeshDetails(MeshA, Animation);

			bTransitioningToB = true;
			bTransitionActive = false;
			ActiveMesh = MeshAsset;
			ActiveAnimation = Animation;

			AMainMenu MainMenu = ActorList::GetSingle(AMainMenu);
			if (MainMenu.CameraUser != nullptr)
				MainMenu.CameraUser.UserComp.TriggerCameraCutThisFrame();

			return;
		}

		if (bTransitionActive)
		{
			PendingMesh = MeshAsset;
			PendingAnimation = Animation;
			return;
		}

		bTransitionActive = true;
		TransitionTimer = 0.0;
		ActiveMesh = MeshAsset;
		ActiveAnimation = Animation;
		PendingMesh = nullptr;
		PendingAnimation = nullptr;

		UHazeCharacterSkeletalMeshComponent StartMesh;
		UHazeCharacterSkeletalMeshComponent EndMesh;

		if (bTransitioningToB)
		{
			StartMesh = MeshA;
			EndMesh = MeshB;
		}
		else
		{
			StartMesh = MeshB;
			EndMesh = MeshA;
		}

		EndMesh.SetHiddenInGame(false);
		EndMesh.SetSkeletalMeshAsset(MeshAsset);
		for (int i = 0, Count = EndMesh.NumMaterials; i < Count; ++i)
			EndMesh.SetMaterial(i, EndMesh.SkeletalMeshAsset.Materials[i].MaterialInterface);

		StartMesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 1.0);
		EndMesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 1.0);

		float DownDistance = 1000;
		float PlayerRadius = 100;

		FVector SphereCenter = StartMesh.GetSocketTransform(n"Hips").GetLocation() - FVector(0, 0, DownDistance);
		float SphereRadius = (DownDistance - PlayerRadius);

		UpdateWhiteSpaceBlend(EndMesh, SphereCenter, SphereRadius, false);
		UpdateWhiteSpaceBlend(StartMesh, SphereCenter, SphereRadius, true);
		UpdateMeshDetails(EndMesh, Animation);

		UMenuEffectEventHandler::Trigger_OnChapterSelectPlayerMesh(
			Menu::GetAudioActor(),
			FChapterSelectPlayerMeshData(ActiveMesh, TransitionDuration));
	}

	void UpdateMeshDetails(USkeletalMeshComponent MeshComp, UAnimSequence Animation)
	{
		USkeletalMesh MeshAsset = MeshComp.GetSkeletalMeshAsset();
		if (MeshAsset.Name == n"RainbowPig" || MeshAsset.Name == n"StretchyPig")
		{
			MeshComp.SetWorldScale3D(FVector(0.75));
			MeshComp.SetRelativeLocation(FVector(-30, 0, 0));
		}
		else if (MeshAsset.Name == n"MioTooth" || MeshAsset.Name == n"ZoeTooth")
		{
			MeshComp.SetWorldScale3D(FVector(0.7));
			MeshComp.SetRelativeLocation(FVector(-30, 0, 0));
		}
		else
		{
			MeshComp.SetWorldScale3D(FVector::OneVector);
			MeshComp.SetRelativeLocation(FVector::ZeroVector);
		}

		if (MeshAsset.Name == n"MioTooth" || MeshAsset.Name == n"ZoeTooth")
		{
			if (GooglyEyes.Num() == 0)
			{
				GooglyEyes.Add(SpawnActor(GooglyEyeClass));
				GooglyEyes.Last().Root.bAbsoluteScale = false;	// The googly eye scale is absolute by default (for reasons), ignore that here
				GooglyEyes.Last().AttachToComponent(MeshComp, n"LeftEyeAttach", EAttachmentRule::SnapToTarget);
				GooglyEyes.Last().BoundaryRadius = 20.0;
				GooglyEyes.Last().UpdateMeshScale();
				GooglyEyes.Last().Reset();
				GooglyEyes.Last().SetActorRelativeScale3D(FVector::OneVector);

				GooglyEyes.Add(SpawnActor(GooglyEyeClass));
				GooglyEyes.Last().Root.bAbsoluteScale = false;
				GooglyEyes.Last().AttachToComponent(MeshComp, n"RightEyeAttach", EAttachmentRule::SnapToTarget);
				GooglyEyes.Last().BoundaryRadius = 15.0;
				GooglyEyes.Last().UpdateMeshScale();
				GooglyEyes.Last().Reset();
				GooglyEyes.Last().SetActorRelativeScale3D(FVector::OneVector);
			}
			else
			{
				for (ADentistGooglyEye Eyes : GooglyEyes)
				{
					Eyes.RemoveActorVisualsBlock(this);
					Eyes.AttachToComponent(MeshComp, Eyes.AttachParentSocketName, AttachmentRule = EAttachmentRule::KeepRelative);
					Eyes.Reset();
				}
			}
		}
		else
		{
			for (ADentistGooglyEye Eyes : GooglyEyes)
			{
				Eyes.AddActorVisualsBlock(this);
			}
		}

		bool bIsSketchbook = Animation.Name == n"Mio_Bhv_ChapterSelect_Sketchbook" || Animation.Name == n"Zoe_Bhv_ChapterSelect_Sketchbook";
		if (bIsSketchbook)
		{
			SketchbookPostProcess.bEnabled = true;
			MeshComp.SetRenderCustomDepth(true);
			MeshComp.SetDisablePostProcessBlueprint(true);
			MeshComp.bDisableClothSimulation = true;
			bWantPostProcess = true;

			if (SketchbookEyeMaterial != nullptr)
				MeshComp.SetMaterial(SketchbookEyeMaterialIndex, SketchbookEyeMaterial);
		}
		else
		{
			SketchbookPostProcess.bEnabled = false;
			MeshComp.SetDisablePostProcessBlueprint(false);
			MeshComp.bDisableClothSimulation = false;
			MeshComp.SetRenderCustomDepth(false);
			bWantPostProcess = false;
		}
	}

	void UpdateWhiteSpaceBlend(UMeshComponent Mesh, FVector Center, float Radius, bool bFlip = true)
	{
		Mesh.SetVectorParameterValueOnMaterials(n"Glitch_Center", Center);
		Mesh.SetScalarParameterValueOnMaterials(n"Glitch_Radius", Radius);
		Mesh.SetScalarParameterValueOnMaterials(n"Glitch_Flip", bFlip ? 1.0 : 0.0);
		Mesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTransitionActive)
		{
			UHazeCharacterSkeletalMeshComponent StartMesh;
			UHazeCharacterSkeletalMeshComponent EndMesh;

			if (bTransitioningToB)
			{
				StartMesh = MeshA;
				EndMesh = MeshB;
			}
			else
			{
				StartMesh = MeshB;
				EndMesh = MeshA;
			}

			TransitionTimer += DeltaSeconds;

			float TransitionAlpha = TransitionTimer / TransitionDuration;
			if (TransitionAlpha >= 1.0)
			{
				StartMesh.SetHiddenInGame(true);
				// EndMesh.SetScalarParameterValueOnMaterials(n"HazeToggle_Glitch_Enabled", 0.0);

				bTransitionActive = false;
				bTransitioningToB = !bTransitioningToB;

				// Start next transition if one was waiting
				if (PendingMesh != nullptr && (PendingMesh != ActiveMesh || PendingAnimation != ActiveAnimation))
					TransitionToMesh(PendingMesh, PendingAnimation);

				PendingMesh = nullptr;
				PendingAnimation = nullptr;
			}
			else
			{

				float DownDistance = 1000;
				float PlayerRadius = 100;

				FVector SphereCenter = StartMesh.GetSocketTransform(n"Hips").GetLocation() - FVector(0, 0, DownDistance);
				float SphereRadius = (DownDistance - PlayerRadius) + TransitionAlpha * PlayerRadius*2.0;

				UpdateWhiteSpaceBlend(EndMesh, SphereCenter, SphereRadius, false);
				UpdateWhiteSpaceBlend(StartMesh, SphereCenter, SphereRadius, true);
			}
		}

		for (ADentistGooglyEye Eyes : GooglyEyes)
			Eyes.SetActorHiddenInGame(IsHidden());

		if (IsHidden())
			SketchbookPostProcess.bEnabled = false;
		else
			SketchbookPostProcess.bEnabled = bWantPostProcess;
	}
}