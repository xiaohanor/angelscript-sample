UCLASS(NotBlueprintable)
class AJetskiSpline : ASplineActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UJetskiSplineEditorComponent EditorComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	TArray<UJetskiSplineCameraLookComponent> LookComponents;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Spline.UpdateSpline();
		RefreshCameraLookComponents();
		Spline.EditingSettings.VisualizeScale = 1;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RefreshCameraLookComponents();
	}

	void RefreshCameraLookComponents()
	{
		LookComponents.Reset();

		GetComponentsByClass(UJetskiSplineCameraLookComponent, LookComponents);
		for (auto LookComp : LookComponents)
			LookComp.RefreshDistanceAlongSpline();

		LookComponents.Sort();
	}

	// @return False if only one or no components are valid, thus not making interpolation possible
	bool GetCameraLookComponents(float DistanceAlongSpline, UJetskiSplineCameraLookComponent&out Previous, UJetskiSplineCameraLookComponent&out Next, float&out Alpha) const
	{
		if(LookComponents.Num() == 0)
		{
			Previous = nullptr;
			Next = nullptr;
			Alpha = 0;
			return false;
		}

		if(LookComponents.Num() == 1)
		{
			Previous = nullptr;
			Next = LookComponents[0];
			Alpha = 1;
			return false;
		}

		if(DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < LookComponents[0].DistanceAlongSpline)
		{
			// Before the spline or the first look component
			Previous = LookComponents[0];
			Next = LookComponents[1];
			Alpha = 0;
			return true;
		}

		if(DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > LookComponents[LookComponents.Num() - 1].DistanceAlongSpline)
		{
			// After the spline or the last look component
			Previous = LookComponents[LookComponents.Num() - 2];
			Next = LookComponents[LookComponents.Num() - 1];
			Alpha = 1;
			return true;
		}

		// FB TODO: Faster search?
		for(int i = 1; i < LookComponents.Num(); i++)
		{
			UJetskiSplineCameraLookComponent PreviousComp = LookComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			UJetskiSplineCameraLookComponent NextComp = LookComponents[i];
			if(NextComp.DistanceAlongSpline < DistanceAlongSpline)
				continue;
			
			Previous = PreviousComp;
			Next = NextComp;

			Alpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousComp.DistanceAlongSpline, NextComp.DistanceAlongSpline);
			return true;
		}

		check(false);
		return false;
	}

	TOptional<FJetskiSplineCameraLookSettings> GetCameraLookSettingsAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		if(LookComponents.Num() == 0)
			return TOptional<FJetskiSplineCameraLookSettings>();

		if(LookComponents.Num() == 1 || DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < LookComponents[0].DistanceAlongSpline)
			return LookComponents[0].Settings;

		if(DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > LookComponents[LookComponents.Num() - 1].DistanceAlongSpline)
			return LookComponents[LookComponents.Num() - 1].Settings;

		UJetskiSplineCameraLookComponent Previous;
		UJetskiSplineCameraLookComponent Next;
		float Alpha;
		bool bSuccess = GetCameraLookComponents(DistanceAlongSpline, Previous, Next, Alpha);
		check(bSuccess);

		// Smooth it out
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		return TOptional<FJetskiSplineCameraLookSettings>(Previous.Settings.Lerp(Next.Settings, Alpha));
	}

	FRotator GetCameraRotationOffsetAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		TOptional<FJetskiSplineCameraLookSettings> CameraLookSettings = GetCameraLookSettingsAtDistanceAlongSpline(DistanceAlongSpline);
		if(!CameraLookSettings.IsSet())
			return FRotator::ZeroRotator;
		return CameraLookSettings.Value.RotationOffset;
	}
};

#if EDITOR
class UJetskiSplineEditorComponent : UActorComponent
{
};

class UJetskiSplineEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiSplineEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AJetskiSpline Spline = Cast<AJetskiSpline>(Component.Owner);
		UHazeSplineComponent SplineComp = Spline.Spline;

		if(SplineComp == nullptr)
			return;

		Spline.RefreshCameraLookComponents();

		DrawJetskiCameraLookComponents(Spline);
	}

	private void DrawJetskiCameraLookComponents(AJetskiSpline Spline) const
	{
		Spline.LookComponents.Reset();
		Spline.GetComponentsByClass(UJetskiSplineCameraLookComponent, Spline.LookComponents);
		Spline.LookComponents.Sort();

		const float Interval = 5000;
		float Distance = 0;
		float DistanceOffset = Time::GameTimeSeconds * 2000;
		while(Distance < Spline.Spline.SplineLength)
		{
			Distance += Interval;

			float TestDistance = (Distance + DistanceOffset) % Spline.Spline.SplineLength;
			FTransform Transform = Spline.Spline.GetWorldTransformAtSplineDistance(TestDistance);
			if(Editor::EditorViewLocation.DistSquared(Transform.Location) > Math::Square(20000))
				continue;

			FVector Location = Transform.Location + Transform.Rotation.UpVector * 500;
			FRotator RotationOffset = Spline.GetCameraRotationOffsetAtDistanceAlongSpline(TestDistance);
			FRotator Rotation = Transform.TransformRotation(RotationOffset);
			DrawCoordinateSystem(Location, Rotation, 500, 50);
		}
	}
};

class UJetskiSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AJetskiSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Jetski Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddDiveZone;
			AddDiveZone.DelegateParam = n"AddDiveZone";
			AddDiveZone.Label = "Add Dive Zone";
			AddDiveZone.Icon = n"Icons.Plus";
			Menu.AddOption(AddDiveZone, MenuDelegate);
		}

		{
			FHazeContextOption AddForceThrottle;
			AddForceThrottle.DelegateParam = n"AddForceThrottle";
			AddForceThrottle.Label = "Add Force Throttle";
			AddForceThrottle.Icon = n"Icons.Plus";
			Menu.AddOption(AddForceThrottle, MenuDelegate);
		}

		{
			FHazeContextOption AddIgnoreRubberBanding;
			AddIgnoreRubberBanding.DelegateParam = n"AddIgnoreRubberBanding";
			AddIgnoreRubberBanding.Label = "Add Ignore Rubber Banding";
			AddIgnoreRubberBanding.Icon = n"Icons.Plus";
			Menu.AddOption(AddIgnoreRubberBanding, MenuDelegate);
		}

		{
			FHazeContextOption AddAllowAligningWithCeiling;
			AddAllowAligningWithCeiling.DelegateParam = n"AddAllowAligningWithCeiling";
			AddAllowAligningWithCeiling.Label = "Add Allow Aligning with Ceiling";
			AddAllowAligningWithCeiling.Icon = n"Icons.Plus";
			Menu.AddOption(AddAllowAligningWithCeiling, MenuDelegate);
		}

		{
			FHazeContextOption AddUnderwaterZone;
			AddUnderwaterZone.DelegateParam = n"AddUnderwaterZone";
			AddUnderwaterZone.Label = "Add Underwater Zone";
			AddUnderwaterZone.Icon = n"Icons.Plus";
			Menu.AddOption(AddUnderwaterZone, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddDiveZone")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UJetskiSplineDiveZoneComponent);
		}
		else if(OptionName == n"AddForceThrottle")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UJetskiSplineForceThrottleComponent);
		}
		else if(OptionName == n"AddIgnoreRubberBanding")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UJetskiSplineIgnoreRubberBandingComponent);
		}
		else if(OptionName == n"AddAllowAligningWithCeiling")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UJetskiSplineAllowAligningWithCeilingComponent);
		}
		else if(OptionName == n"AddUnderwaterZone")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UJetskiSplineUnderwaterZoneComponent);
		}
	}
};
#endif