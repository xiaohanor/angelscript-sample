
namespace CameraDebug
{
	const FString CategoryCamera = "10#Camera";
	const FString CategoryView = "11#View";
	const FString CategoryCameraTransform = "12#Camera";
	const FString CategoryUser = "13#User";

	const FString CategoryUpdater = "30#Updater";
	const FString CategoryBlend = "35#Blend";
		
	const FString CategorySettings = "40#Settings";
	const FString CategoryModifiers = "45#Modifiers";
	const FString CategoryPOI = "47#POI";
	const FString CategoryClamps = "50#Clamps";
	const FString CategoryKeepInView = "60#KeepInView";
	const FString CategoryShapes = "90#DebugShapes";
	const FString CategoryViewInstigator = "95#Instigators";
	const FString CameraCollision = "99#CameraCollision";


	void DrawDebugInstigators(FTemporalLog TemporalLog, FString Value, TArray<FInstigator> Instigators)
	{
		FString InstigatorInfo = "";
		bool bIsFirst = true;
		for(int i = Instigators.Num() - 1; i >= 0; --i)
		{
			auto It = Instigators[i];
			if(!bIsFirst)
				InstigatorInfo += "\n";
			else
				bIsFirst = false;

			InstigatorInfo += f"{It}";
		}
		TemporalLog.Value(f"{CategoryViewInstigator};{Value}:", InstigatorInfo);
	}
}


mixin void VisualizeCameraEditorPreviewLocation(UHazeCameraComponent Camera, UHazeScriptComponentVisualizer Visualizer)
{
#if EDITOR
	FTransform ViewTransform;
	float EditorFOV = 70;
	Camera.GetEditorPreviewTransform(ViewTransform, EditorFOV);

	FVector CameraLocation = ViewTransform.Location;
	float Dist = CameraLocation.Distance(Visualizer.EditorViewLocation);

	float Length = Math::GetMappedRangeValueClamped(FVector2D(1, 90), FVector2D(250, 500), EditorFOV);

	FVector LookAt = CameraLocation + (ViewTransform.Rotation.ForwardVector * Length);
	if(Dist > SMALL_NUMBER)
	{
		float Size = Math::Max(Math::Min(Dist / 10000, 1) * Length, 3);
		Visualizer.DrawWireStar(CameraLocation, Size, FLinearColor::Black);
		Visualizer.DrawArc(CameraLocation, EditorFOV, Length, ViewTransform.Rotation.ForwardVector, FLinearColor::Black);
		//Visualizer.DrawDashedLine(ViewTransform.Location, Camera.WorldLocation, FLinearColor::Gray, 50);
		//Visualizer.DrawArrow(CameraLocation, LookAt, FLinearColor::Black, Size, Size / 10);
		Visualizer.DrawWorldString("    Position", CameraLocation, FLinearColor::Gray);
		Visualizer.DrawWorldString("    View Direction", LookAt, FLinearColor::Gray);
	}
#endif
}

