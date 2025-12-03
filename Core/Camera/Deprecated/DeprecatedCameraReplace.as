

namespace CameraReplace
{
	void CopyTargets(const UCameraWeightedTargetComponent Source, UCameraWeightedTargetComponent Target)
	{
    	Target.Targets = Source.Targets;
		Target.EmptyTargetDefaultType = Source.EmptyTargetDefaultType;
		Target.PlayerFocusSettingsOverride = Source.PlayerFocusSettingsOverride;
	}

	void CopyOptionalTargets(const UCameraWeightedTargetOptionalComponent Source, UCameraWeightedTargetOptionalComponent Target)
	{
		Target.bUseCustomLocationTargets = Source.bUseCustomLocationTargets;
		Target.CustomLocationTargets = Source.CustomLocationTargets;
	}

	void CopySpline(const UHazeSplineComponent Source, UHazeSplineComponent Target)
	{
		Target.SplinePoints = Source.SplinePoints;
		Target.SplineSettings = Source.SplineSettings;
		Target.EditingSettings = Source.EditingSettings;
		Target.ComputedSpline = Source.ComputedSpline;
		Target.bSpecifyConnections = Source.bSpecifyConnections;
		Target.StartConnection = Source.StartConnection;
		Target.EndConnection = Source.EndConnection;
		Target.bAlignLastPointToEndConnection = Source.bAlignLastPointToEndConnection;
		Target.bAlignFirstPointToStartConnection = Source.bAlignFirstPointToStartConnection;
		Target.SplineConnections = Source.SplineConnections;

		#if EDITOR
		Target.BuilderState = Source.BuilderState;
		#endif
	}

	void ReplaceCamera(AHazeCameraActor OriginalCamera, AHazeCameraActor NewCamera)
	{
		#if EDITOR
		auto AllZones = Editor::GetAllEditorWorldActorsOfClass(AVolume);
		for(auto Zone : AllZones)
		{
			TArray<UHazeCameraSettingsComponent> CameraSettings;
			Zone.GetComponentsByClass(CameraSettings);
			
			for(auto Setting : CameraSettings)
			{
				if(Setting.Camera != OriginalCamera)
					continue;

				Setting.ReplaceCamera(NewCamera);
			}
		}

		OriginalCamera.DestroyActor();
		NewCamera.EditorReplaceActorLevelRefs(OriginalCamera);
		Editor::SelectActor(NewCamera);
		#endif
	}
}