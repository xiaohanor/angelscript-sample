class UScenepointAnimationComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UScenepointAnimationComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UScenepointAnimationComponent SpAnimComp = Cast<UScenepointAnimationComponent>(Component);
        if (!ensure((SpAnimComp != nullptr) && (SpAnimComp.Owner != nullptr)))
            return;
		if (SpAnimComp.EntryAnimation == nullptr)
			return;

		UAnimSequence Anim = SpAnimComp.EntryAnimation;

		auto EditorVisSubsys = UEditorVisualizationSubsystem::Get();

		FVector PreviewScale = FVector::OneVector;
		USkeletalMesh PreviewMesh = GetPreviewMesh(SpAnimComp, SpAnimComp.EntryAnimation, PreviewScale);
		FTransform PreviewTransform = SpAnimComp.Owner.ActorTransform;
		PreviewTransform.SetScale3D(PreviewTransform.Scale3D * PreviewScale);

		UHazeEditorPreviewSkeletalMeshComponent PreviewMeshComp = EditorVisSubsys.DrawAnimation(
			PreviewTransform, Anim, Anim.PlayLength * SpAnimComp.PreviewFraction,
			true, PreviewMesh);

		UHazeEditorPreviewSkeletalMeshComponent EndPosMeshComp = EditorVisSubsys.DrawAnimation(
			PreviewTransform, Anim, Anim.PlayLength,
			true, PreviewMesh);

		FTransform Transform = (PreviewMeshComp.AttachParent == nullptr) ? SpAnimComp.Owner.ActorTransform : PreviewMeshComp.AttachParent.WorldTransform;
		int NumIntervals = Math::Clamp(Math::CeilToInt(Anim.PlayLength * 20), 3, 200);
		FVector PrevLoc = Transform.Location;
		float Fraction = Anim.PlayLength / NumIntervals;

		FHazeLocomotionTransform TotalRootMotion;
		if (Anim.ExtractTotalRootMotion(TotalRootMotion) && !TotalRootMotion.DeltaTranslation.IsNearlyZero(1.0))
		{
			FLinearColor Color = FLinearColor::Yellow;
			for (int i = 1; i <= NumIntervals; i++)
			{
				FHazeLocomotionTransform RootMotion;
				if (!Anim.ExtractRootMotion(0.0, Fraction * i, RootMotion))
					continue;
				FVector Loc = Transform.TransformPosition(RootMotion.DeltaTranslation); 
				DrawLine(PrevLoc, Loc, Color, 5.0);
				PrevLoc = Loc;
			}
		}
		else
		{
			// No root motion, use motion of hips or first bone which is a child of root
			FName Bone = NAME_None;
			FLinearColor Color = FLinearColor::Gray;
			for (int iBone = 1; iBone < PreviewMeshComp.NumBones; iBone++)
			{
				if (PreviewMeshComp.GetBoneName(iBone) == n"Align")
					continue;
				if (PreviewMeshComp.IsBoneChildOf(iBone, 0))
				{
					Bone = PreviewMeshComp.GetBoneName(iBone);
					break;
				}
			}
			if (!Bone.IsNone())
			{
				FTransform MeshTransform = PreviewMeshComp.WorldTransform;
				FTransform StartTransform;
				Anim.GetAnimBoneTransform(StartTransform, Bone, 0.0);
				PrevLoc = MeshTransform.TransformPosition(StartTransform.Location);
				for (int i = 1; i <= NumIntervals; i++)
				{
					FTransform BoneTransform;
					Anim.GetAnimBoneTransform(BoneTransform, Bone, Fraction * i);
					FVector Loc = MeshTransform.TransformPosition(BoneTransform.Location); 
					DrawLine(PrevLoc, Loc, Color, 5.0);
					PrevLoc = Loc;
				}
			}
		}
	}

	USkeletalMesh GetPreviewMesh(UScenepointAnimationComponent ScenepointComp, UAnimSequence Anim, FVector& PreviewScale)
	{
		PreviewScale = FVector::OneVector;
		USkeletalMesh PreviewMesh = nullptr;
		if (ScenepointComp.PreviewClass.IsValid())
		{
			AHazeCharacter CharCDO = Cast<AHazeCharacter>(ScenepointComp.PreviewClass.Get().DefaultObject);
			if ((CharCDO != nullptr) && (CharCDO.Mesh != nullptr))
			{
				PreviewMesh = CharCDO.Mesh.SkeletalMeshAsset;
				PreviewScale = CharCDO.Mesh.RelativeScale3D;				
			}
			else		
			{
				AActor ActorCDO = Cast<AActor>(ScenepointComp.PreviewClass.Get().DefaultObject);
				UHazeSkeletalMeshComponentBase CDOMeshComp	= (ActorCDO != nullptr) ? UHazeSkeletalMeshComponentBase::Get(ActorCDO) : nullptr;			 
				if (CDOMeshComp != nullptr)
				{
					PreviewMesh = CDOMeshComp.SkeletalMeshAsset;
					PreviewScale = CDOMeshComp.RelativeScale3D;				
				}
			}
		}
		return PreviewMesh;
	}
}

#if EDITOR
class UScenepointAnimationComponentDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UScenepointAnimationComponent;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		if (GetCustomizedObject().World == nullptr)
			return; // BP editor

		Drawer = AddImmediateRow(n"Preview");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GetCustomizedObject().World == nullptr)
			return; // BP editor

		if (!Drawer.IsVisible())
			return;
		
		auto MainAnimComp = Cast<UScenepointAnimationComponent>(GetCustomizedObject());
		if (MainAnimComp == nullptr)
			return;	

		FHazeImmediateSectionHandle Section = Drawer.Begin();
		bool bIsPlaying = MainAnimComp.bIsPreviewPlaying;
		FHazeImmediateButtonHandle Button = Section.Button(bIsPlaying ? "||" : "▶");
		if(Button)
		{	
			// Toggle playing/paused
			bIsPlaying = !bIsPlaying;
			for (UObject Object : ObjectsBeingCustomized)
			{
				auto AnimComp = Cast<UScenepointAnimationComponent>(Object);
				if(AnimComp == nullptr)
					continue;
				AnimComp.bIsPreviewPlaying = bIsPlaying;		
			}
		}
		Drawer.End();

		if (bIsPlaying)
		{
			for (UObject Object : ObjectsBeingCustomized)
			{
				auto AnimComp = Cast<UScenepointAnimationComponent>(Object);
				if(AnimComp == nullptr)
					continue;
				if (AnimComp.EntryAnimation == nullptr)
					continue;
				float AnimDuration = AnimComp.EntryAnimation.PlayLength;
				if (AnimDuration == 0.0)
					continue;
				float AnimTime = AnimDuration * AnimComp.PreviewFraction + DeltaTime;
				if (AnimTime > AnimDuration)
					AnimTime = AnimTime - AnimDuration; // Loop
				AnimComp.PreviewFraction = AnimTime / AnimDuration;
			}
		}
	}
}
#endif


