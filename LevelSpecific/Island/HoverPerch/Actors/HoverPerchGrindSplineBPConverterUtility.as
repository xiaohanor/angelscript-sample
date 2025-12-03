#if EDITOR
class UHoverPerchGrindSplineBPConverterUtility : UScriptActorMenuExtension
{
	default SupportedClasses.Add(AHoverPerchGrindSpline);
	default ExtensionPoint = n"ActorTypeTools";

	UFUNCTION(CallInEditor, DisplayName = "Replace Selected Grinds with", Meta = (EditorIcon = "Icons.ReplaceActor"))
	void ReplaceSelectedGrindsWith(TSoftClassPtr<AHoverPerchGrindSpline> GrindClass)
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		for(AActor Actor : SelectedActors)
		{
			if(Actor.Class == GrindClass.Get())
				continue;

			auto Grind = Cast<AHoverPerchGrindSpline>(Actor);
			auto NewGrind = SpawnActor(GrindClass.Get(), Grind.ActorLocation, Grind.ActorRotation, Grind.Name);

			// Copy actor properties
			NewGrind.SplineBoundsDistance = Grind.SplineBoundsDistance;
			NewGrind.bUseBoxForStart = Grind.bUseBoxForStart;
			NewGrind.GrindEnterDistance = Grind.GrindEnterDistance;
			NewGrind.StartBoxExtents = Grind.StartBoxExtents;
			NewGrind.GrindMaxSpeed = Grind.GrindMaxSpeed;
			NewGrind.GrindAcceleration = Grind.GrindAcceleration;
			NewGrind.GrindElevationChange = Grind.GrindElevationChange;
			NewGrind.bGrindBackwards = Grind.bGrindBackwards;
			NewGrind.bDebugDrawElevationChange = Grind.bDebugDrawElevationChange;
			NewGrind.bSwitchDirectionWhenHittingOtherHoverPerch = Grind.bSwitchDirectionWhenHittingOtherHoverPerch;
			NewGrind.PlayerDamageToApplyWhenSwitchingDirectionOnHit = Grind.PlayerDamageToApplyWhenSwitchingDirectionOnHit;
			NewGrind.bChangeMaterialWhenGrinding = Grind.bChangeMaterialWhenGrinding;
			NewGrind.MaterialIndexToChangeWhenGrinding = Grind.MaterialIndexToChangeWhenGrinding;
			NewGrind.MioGrindingMaterial = Grind.MioGrindingMaterial;
			NewGrind.ZoeGrindingMaterial = Grind.ZoeGrindingMaterial;
			NewGrind.BothGrindingMaterial = Grind.BothGrindingMaterial;
			NewGrind.bBlockOtherPlayerRespawnWhileOnGrind = Grind.bBlockOtherPlayerRespawnWhileOnGrind;
			NewGrind.bGameOverIfBothDie = Grind.bGameOverIfBothDie;

			NewGrind.bConnectsToOtherSplines = Grind.bConnectsToOtherSplines;
			NewGrind.bStartConnects = Grind.bStartConnects;
			NewGrind.StartConnectingGrind = Grind.StartConnectingGrind;
			NewGrind.bStartConnectsBothWays = Grind.bStartConnectsBothWays;
			NewGrind.bStartConnectsBackwards = Grind.bStartConnectsBackwards;
			NewGrind.bStartConnectsFromBackwards = Grind.bStartConnectsFromBackwards;
			NewGrind.bStartConnectionRequiresSteering = Grind.bStartConnectionRequiresSteering;
			NewGrind.bPlaceStartConnectionOnSpline = Grind.bPlaceStartConnectionOnSpline;

			NewGrind.bEndConnects = Grind.bEndConnects;
			NewGrind.EndConnectingGrind = Grind.EndConnectingGrind;
			NewGrind.bEndConnectsBothWays = Grind.bEndConnectsBothWays;
			NewGrind.bEndConnectsBackwards = Grind.bEndConnectsBackwards;
			NewGrind.bEndConnectsFromBackwards = Grind.bEndConnectsFromBackwards;
			NewGrind.bEndConnectionRequiresSteering = Grind.bEndConnectionRequiresSteering;
			NewGrind.bPlaceEndConnectionOnSpline = Grind.bPlaceEndConnectionOnSpline;

			NewGrind.GrindCenterOffset = Grind.GrindCenterOffset;
			NewGrind.GrindBoundsExtent = Grind.GrindBoundsExtent;

			// Spline stuff
			UHazeSplineComponent Spline = Spline::GetGameplaySpline(Grind, this);
			UHazeSplineComponent NewSpline = Spline::GetGameplaySpline(NewGrind, this);

			NewSpline.SplinePoints = Spline.SplinePoints;
			NewSpline.SplineConnections = Spline.SplineConnections;
			NewSpline.SplineSettings = Spline.SplineSettings;
			NewSpline.bSpecifyConnections = Spline.bSpecifyConnections;

			// Prop line stuff
			NewGrind.Preset = Grind.Preset;
			NewGrind.MergedMeshes = Grind.MergedMeshes;
			NewGrind.Settings = Grind.Settings;
			NewGrind.Type = Grind.Type;
			NewGrind.MeshDistribution = Grind.MeshDistribution;
			NewGrind.MeshStretching = Grind.MeshStretching;
			NewGrind.Segments = Grind.Segments;
			NewGrind.RandomizeTweak = Grind.RandomizeTweak;
			NewGrind.MaximumMergedMeshSize = Grind.MaximumMergedMeshSize;
			NewGrind.MaximumTotalMeshes = Grind.MaximumTotalMeshes;
			NewGrind.bMoveActorPivotToFirstSplinePoint = Grind.bMoveActorPivotToFirstSplinePoint;
			NewGrind.bShowMeshesInDetailsView = Grind.bShowMeshesInDetailsView;
			NewGrind.bGameplaySpline = Grind.bGameplaySpline;
			NewGrind.bIsUsingInstanceComponents = Grind.bIsUsingInstanceComponents;
			NewGrind.bHasAddedDefaultMesh = Grind.bHasAddedDefaultMesh;

			UEditorActorSubsystem::Get().DestroyActor(Grind);
			Editor::ToggleActorSelected(NewGrind);
		}
	}
}
#endif