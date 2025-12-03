struct FJetskiSplineCameraLookSettings
{
	UPROPERTY()
	FRotator RotationOffset;

	UPROPERTY()
	float AdditiveIdealDistance = 0;

	UPROPERTY()
	float AdditiveFOV = 0;

	FJetskiSplineCameraLookSettings Lerp(const FJetskiSplineCameraLookSettings B, float Alpha) const
	{
		FJetskiSplineCameraLookSettings Result;
		Result.RotationOffset = Math::LerpShortestPath(RotationOffset, B.RotationOffset, Alpha);
		Result.AdditiveIdealDistance = Math::Lerp(AdditiveIdealDistance, B.AdditiveIdealDistance, Alpha);
		Result.AdditiveFOV = Math::Lerp(AdditiveFOV, B.AdditiveFOV, Alpha);
		return Result;
	}
}

/**
 * This component allows for changing camera settings by blending values when between components on the spline
 */
UCLASS(NotBlueprintable, HideCategories = "CameraSettings CameraOptions Camera PostProcess Debug Activation Cooking Tags Collision Rendering LOD")
class UJetskiSplineCameraLookComponent : UCameraComponent
{
	default FieldOfView = 70;

	UPROPERTY(EditInstanceOnly)
	FJetskiSplineCameraLookSettings Settings;

	UPROPERTY(VisibleInstanceOnly, Transient)
	float DistanceAlongSpline = -1;

	private UHazeSplineComponent SplineComp;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		RefreshDistanceAlongSpline();
		SnapToSpline();
		FieldOfView = Cast<UCameraSettings>(UCameraSettings.DefaultObject).FOV.Value + Settings.AdditiveFOV;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
		RefreshDistanceAlongSpline();
	}

	void RefreshSpline()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);
		check(HasValidSpline());
	}

	void SnapToSpline()
	{
		if(!ensure(HasValidSpline()))
			return;

		if(!ensure(DistanceAlongSpline >= 0))
			return;

		FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);

		FRotator Rotation = SplineTransform.TransformRotation(Settings.RotationOffset);

		SetWorldLocationAndRotation(SplineTransform.Location, Rotation);
	}

	void RefreshDistanceAlongSpline()
	{
		if(!(HasValidSpline()))
			RefreshSpline();

		DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}

	bool HasValidSpline() const
	{
		if(SplineComp == nullptr)
			return false;

		if(SplineComp.SplinePoints.Num() < 2)
			return false;

		if(SplineComp.SplineLength < 1)
			return false;

		return true;
	}

	int opCmp(UJetskiSplineCameraLookComponent Other) const
	{
		if(DistanceAlongSpline > Other.DistanceAlongSpline)
			return 1;
		else
			return -1;
	}
};

#if EDITOR
class UJetskiSplineCameraLookComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiSplineCameraLookComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		if(!Editor::IsComponentSelected(Component))
			return;

		auto LookComp = Cast<UJetskiSplineCameraLookComponent>(Component);
		if(LookComp == nullptr)
			return;

		auto Spline = Cast<AJetskiSpline>(LookComp.Owner);
		if(Spline == nullptr)
			return;

		VisualizeSettings(LookComp, Spline);
		VisualizeSettingsAtLineFromCamera(Spline);
	}

	void VisualizeSettings(UJetskiSplineCameraLookComponent LookComp, AJetskiSpline Spline)
	{
		const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(LookComp.WorldLocation);
		DrawWireSphere(Location, 500, FLinearColor::Yellow, 3, 12, true);
	}

	void VisualizeSettingsAtLineFromCamera(AJetskiSpline Spline) const
	{
		const FSplinePosition SplinePosition = Spline.Spline.GetClosestSplinePositionToLineSegment(EditorViewLocation, EditorViewLocation + EditorViewRotation.ForwardVector * 10000, false);

		FString Text = "Jetski Spline";

		TOptional<FJetskiSplineCameraLookSettings> CameraLookSettings = Spline.GetCameraLookSettingsAtDistanceAlongSpline(SplinePosition.CurrentSplineDistance);
		if(CameraLookSettings.IsSet())
		{
			Text += f"\nCamera Look Settings";
			Text += f"\n	Rotation Offset {CameraLookSettings.Value.RotationOffset}";
			Text += f"\n	Additive Ideal Distance {CameraLookSettings.Value.AdditiveIdealDistance}";
			Text += f"\n	Additive FOV {CameraLookSettings.Value.AdditiveFOV}";
		}

		DrawWireSphere(SplinePosition.WorldLocation, 100, FLinearColor::White);
		DrawWorldString(Text, SplinePosition.WorldLocation, FLinearColor::White, 1, 10000, true);
	}
};

class UJetskiSplineCameraContextMenuExtension : UHazeSplineContextMenuExtension
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
		return "Jetski Spline Camera";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddCameraLook;
			AddCameraLook.DelegateParam = n"AddCameraLook";
			AddCameraLook.Label = "Add Camera Look";
			AddCameraLook.Icon = n"Icons.Plus";
			Menu.AddOption(AddCameraLook, MenuDelegate);
		}

		AJetskiSpline JetskiSpline = Cast<AJetskiSpline>(Spline.Owner);
		if(JetskiSpline == nullptr)
			return;

		UJetskiSplineCameraLookComponent Previous;
		UJetskiSplineCameraLookComponent Next;
		float Alpha;		
		JetskiSpline.GetCameraLookComponents(ClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr)
		{
			FHazeContextOption DuplicatePreviousCameraLook;
			DuplicatePreviousCameraLook.DelegateParam = n"DuplicatePreviousCameraLook";
			DuplicatePreviousCameraLook.Label = "Duplicate Previous Camera Look";
			DuplicatePreviousCameraLook.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicatePreviousCameraLook, MenuDelegate);
		}

		if(Next != nullptr)
		{
			FHazeContextOption DuplicateNextCameraLook;
			DuplicateNextCameraLook.DelegateParam = n"DuplicateNextCameraLook";
			DuplicateNextCameraLook.Label = "Duplicate Next Camera Look";
			DuplicateNextCameraLook.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicateNextCameraLook, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddCameraLook")
		{
			auto AddedCameraLook = UJetskiSplineCameraLookComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedCameraLook.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedCameraLook);
			Spline.Owner.Modify();
			return;
		}

		AJetskiSpline JetskiSpline = Cast<AJetskiSpline>(Spline.Owner);
		if(JetskiSpline == nullptr)
			return;

		UJetskiSplineCameraLookComponent Previous;
		UJetskiSplineCameraLookComponent Next;
		float Alpha;		
		JetskiSpline.GetCameraLookComponents(MenuClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr && OptionName == n"DuplicatePreviousCameraLook")
		{
			auto AddedCameraLook = UJetskiSplineCameraLookComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedCameraLook.SetWorldTransform(Transform);
			AddedCameraLook.Settings = Previous.Settings;
			Editor::SelectComponent(AddedCameraLook);
			Spline.Owner.Modify();
			return;
		}

		if(Next != nullptr && OptionName == n"DuplicateNextCameraLook")
		{
			auto AddedCameraLook = UJetskiSplineCameraLookComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedCameraLook.SetWorldTransform(Transform);
			AddedCameraLook.Settings = Next.Settings;
			Editor::SelectComponent(AddedCameraLook);
			Spline.Owner.Modify();
			return;
		}
	}
};
#endif