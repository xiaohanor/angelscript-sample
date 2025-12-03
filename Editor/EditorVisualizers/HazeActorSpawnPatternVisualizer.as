class UHazeActorSpawnPatternVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UHazeActorSpawnPattern;

	UHazeActorSpawnPattern SelectedPattern;

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		// We've only got a single hit proxy.
		UHazeActorSpawnPattern Pattern = Cast<UHazeActorSpawnPattern>(EditingComponent);
		Editor::SelectComponent(Pattern);	
		return true;	
	}

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UHazeActorSpawnPattern Pattern = Cast<UHazeActorSpawnPattern>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		SetHitProxy(n"PatternProxy", EVisualizerCursor::Default);
		if (Pattern.bCanEverSpawn || Pattern.CanSpawn())
		{
			// Spawning pattern or a pattern with no spawn class or other property values currently preventing spawning
			FLinearColor Color = Pattern.CanSpawn() ? FLinearColor::Green : FLinearColor::Gray; 
			if (!Pattern.ShouldStartActive())
				Color *= 0.1;
			DrawWireSphere(Pattern.WorldLocation, 100.0, Color, 2.0, 4);
			DrawDashedLine(Pattern.WorldLocation, Pattern.Owner.ActorLocation, Color, 10.0, 1.0);
		}
		else
		{
			// Non spawning patterns actual location is usually not that relevant, visualize them with an offset to help show update order instead
			FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Yellow : FLinearColor::Yellow * 0.2;
			FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * GetDrawOffset(Pattern);
			DrawWireSphere(Loc, 20.0, Color, 1.0, 4);
			DrawDashedLine(Loc, Pattern.Owner.ActorLocation, Color, 5.0, 0.0);
		}
		ClearHitProxy();
	}

	float GetDrawOffset(UHazeActorSpawnPattern Pattern)
	{
		UHazeActorSpawnerComponent SpawnerComp = UHazeActorSpawnerComponent::Get(Pattern.Owner);
		if (SpawnerComp == nullptr)
			return 0.0;

		if (Pattern.CanSpawn() || Pattern.bCanEverSpawn)
			return 0.0;

		return 200.0 + 40.0 * Pattern.VisualOffsetOrder;
	}

	void DrawInternalLink(FVector From, float SideMin, UHazeActorSpawnPattern ToPattern, FLinearColor Colour)
	{
		// Non-spawning pattern, use a graphlike display
		float DrawOffset = GetDrawOffset(ToPattern);
		FVector To = ToPattern.WorldLocation + ToPattern.Owner.ActorUpVector * DrawOffset;

		FVector Delta = To - From;
		FQuat ViewRot = Editor::EditorViewRotation.Quaternion();
		
		// Left/Right
		FVector ViewRight = ViewRot.RightVector;
		float SideDist = ViewRight.DotProduct(Delta);
		if (Math::Abs(SideDist) < SideMin)
			SideDist = SideMin * ((SideDist < 1.0) ? 1.0 : -1.0);
		FVector FromSide = From + ViewRight * SideDist;

		DrawLine(From, FromSide, Colour, 2.0);
		if (ToPattern.bCanEverSpawn || ToPattern.CanSpawn())
		{
			FVector OutsideTo = To - (To - FromSide).GetSafeNormal() * 110.0;
			DrawArrow(FromSide, OutsideTo, Colour, 5.0, 2.0);
		}
		else
		{
			FVector ViewUp = ViewRot.UpVector;
			float VertDist = ViewUp.DotProduct(Delta);
			float VertMin = 20.0;
			if (Math::Abs(VertDist) < VertMin)
				VertDist = VertMin * ((VertDist > 1.0) ? 1.0 : -1.0);
			float VertOffset = Math::Sign(VertDist) * -3.0;;
			FVector ToSide = FromSide + ViewUp * (VertDist + VertOffset);
			FVector OutsideTo = To - (To - ToSide).GetSafeNormal() * 30.0 + ViewUp * VertOffset;
			DrawLine(FromSide, ToSide, Colour, 2.0);
			DrawArrow(ToSide, OutsideTo, Colour, 5.0, 2.0);
		}
	}
}

class UHazeActorSpawnPatternOtherActivateOnCompletedVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternActivateOtherSpawner;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		Super::VisualizeComponent(Component);
#if EDITOR
        UHazeActorSpawnPatternActivateOtherSpawner Pattern = Cast<UHazeActorSpawnPatternActivateOtherSpawner>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		if (Pattern.OtherSpawner != nullptr)
		{
			FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::LucBlue : FLinearColor::LucBlue * 0.2;
			FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * GetDrawOffset(Pattern);
			DrawWireSphere(Loc, 25.0, Color, 1.0, 6);
			DrawDashedLine(Loc, Pattern.OtherSpawner.ActorLocation, Color, 20.0, 3.0);
		}
#endif
	}
}

class UHazeActorSpawnPatternActivateNamedPatternVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternActivateOwnPatterns;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		Super::VisualizeComponent(Component);
#if EDITOR
        UHazeActorSpawnPatternActivateOwnPatterns Pattern = Cast<UHazeActorSpawnPatternActivateOwnPatterns>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		float DrawOffset = GetDrawOffset(Pattern);
		FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * DrawOffset;
		FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Purple: FLinearColor::Purple * 0.2;
		DrawWireSphere(Loc, 25.0, Color, 1.0, 8);

		for (UHazeActorSpawnPattern ActivatePattern : Pattern.PatternsToActivate)
		{
			if (ActivatePattern != nullptr)
				DrawInternalLink(Loc, DrawOffset - 140.0, ActivatePattern, Color);
		}
#endif
	}
}

class UHazeActorSpawnPatternEntryScenepointVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternEntryScenepoint;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		Super::VisualizeComponent(Component);
#if EDITOR
        UHazeActorSpawnPatternEntryScenepoint Pattern = Cast<UHazeActorSpawnPatternEntryScenepoint>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		float DrawOffset = GetDrawOffset(Pattern);
		FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * DrawOffset;
		FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Yellow: FLinearColor::Yellow * 0.2;
		for (AScenepointActorBase Scenepoint : Pattern.EntryScenepoints)
		{
			if (Scenepoint != nullptr)
				DrawDashedLine(Loc, Scenepoint.ActorLocation, Color, 15.0);
		}
#endif
	}
}

class UHazeActorSpawnPatternSpawnAtScenepointVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternSpawnAtScenepoint;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
#if EDITOR
		Super::VisualizeComponent(Component);
        UHazeActorSpawnPatternSpawnAtScenepoint Pattern = Cast<UHazeActorSpawnPatternSpawnAtScenepoint>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		float DrawOffset = GetDrawOffset(Pattern);
		FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * DrawOffset;
		FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Yellow: FLinearColor::Yellow * 0.2;
		for (AScenepointActorBase Scenepoint : Pattern.SpawnScenepoints)
		{
			if (Scenepoint != nullptr)
				DrawDashedLine(Loc, Scenepoint.ActorLocation, Color, 15.0);
		}
#endif
	}
}

class UHazeActorSpawnPatternEntryAnimationVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternEntryAnimation;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		Super::VisualizeComponent(Component);
#if EDITOR
        UHazeActorSpawnPatternEntryAnimation Pattern = Cast<UHazeActorSpawnPatternEntryAnimation>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;
		if (!Pattern.Animations.IsValidIndex(Pattern.PreviewIndex))
			return;

		UAnimSequence Anim = Pattern.Animations[Pattern.PreviewIndex];
		if (Anim == nullptr)
			return;

		if (Pattern.PreviewMeshComp == nullptr)
			return;

		FTransform Transform = (Pattern.PreviewMeshComp.AttachParent == nullptr) ? Pattern.Owner.ActorTransform : Pattern.PreviewMeshComp.AttachParent.WorldTransform;
		int NumIntervals = Math::Clamp(Math::CeilToInt(Anim.PlayLength * 20), 3, 200);
		FVector PrevLoc = Transform.Location;
		float Fraction = Anim.PlayLength / NumIntervals;

		FHazeLocomotionTransform TotalRootMotion;
		if (Anim.ExtractTotalRootMotion(TotalRootMotion) && !TotalRootMotion.DeltaTranslation.IsNearlyZero(1.0))
		{
			FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Yellow: FLinearColor::Yellow * 0.2;
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
			FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Gray: FLinearColor::Gray * 0.2;
			for (int iBone = 1; iBone < Pattern.PreviewMeshComp.NumBones; iBone++)
			{
				if (Pattern.PreviewMeshComp.GetBoneName(iBone) == n"Align")
					continue;
				if (Pattern.PreviewMeshComp.IsBoneChildOf(iBone, 0))
				{
					Bone = Pattern.PreviewMeshComp.GetBoneName(iBone);
					break;
				}
			}
			if (!Bone.IsNone())
			{
				FTransform MeshTransform = Pattern.PreviewMeshComp.WorldTransform;
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
#endif
	}
}

class UHazeActorSpawnPatternEntrySplineVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternEntrySpline;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
#if EDITOR
		Super::VisualizeComponent(Component);
        UHazeActorSpawnPatternEntrySpline Pattern = Cast<UHazeActorSpawnPatternEntrySpline>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		float DrawOffset = GetDrawOffset(Pattern);
		FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * DrawOffset;
		FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Green: FLinearColor::Green * 0.2;
		if (Pattern.SplineOwner != nullptr)
			DrawDashedLine(Loc, Pattern.SplineOwner.ActorLocation, Color, 15.0);
#endif
	}
}

class UHazeActorSpawnPatternFleeSplineVisualizer : UHazeActorSpawnPatternVisualizer
{
    default VisualizedClass = UHazeActorSpawnPatternFleeSpline;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
#if EDITOR
		Super::VisualizeComponent(Component);
        UHazeActorSpawnPatternFleeSpline Pattern = Cast<UHazeActorSpawnPatternFleeSpline>(Component);
        if (!ensure((Pattern != nullptr) && (Pattern.Owner != nullptr)))
            return;

		float DrawOffset = GetDrawOffset(Pattern);
		FVector Loc = Pattern.WorldLocation + Pattern.Owner.ActorUpVector * DrawOffset;
		FLinearColor Color = Pattern.ShouldStartActive() ? FLinearColor::Red: FLinearColor::Red * 0.2;
		for (ASplineActor Spline : Pattern.Splines)
		{
			if (Spline != nullptr)
				DrawDashedLine(Loc, Spline.Spline.WorldLocation, Color, 15.0);
		}
#endif
	}
}
