enum ESanctuaryArenaSplineClampDirection
{
	Left,
	Right 
}

struct FSanctuaryArenaSplineClampData
{
	UPROPERTY(EditAnywhere)
	ESanctuaryArenaSplineClampDirection ClampDirection;
	UPROPERTY(EditAnywhere)
	AInfuseEssenceManager DeactivationEssenceManager;
}

UCLASS(NotBlueprintable)
class USanctuaryArenaClampCameraFocusSplineComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Clamp Data")
	FSanctuaryArenaSplineClampData ClampData;

	private UHazeSplineComponent SplineComp;

	bool bActiveClamp = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RefreshDistanceAlongSpline();
		if (ClampData.DeactivationEssenceManager != nullptr)
		{
			ClampData.DeactivationEssenceManager.OnEssencePickedUp.AddUFunction(this, n"DeactivateClamp");
			ClampData.DeactivationEssenceManager.OnEssenceRespawned.AddUFunction(this, n"ActivateClamp");
		}
	}

	UPROPERTY(VisibleInstanceOnly, Transient)
	float DistanceAlongSpline = -1;

	UFUNCTION()
	private void ActivateClamp()
	{
		bActiveClamp = true;
	}

	UFUNCTION()
	private void DeactivateClamp()
	{
		bActiveClamp = false;
	}

	FLinearColor GetDebugColor()
	{
		if (!bActiveClamp)
			return ColorDebug::Black;
		if (ClampData.ClampDirection == ESanctuaryArenaSplineClampDirection::Left)
			return ColorDebug::Ruby;
		if (ClampData.ClampDirection == ESanctuaryArenaSplineClampDirection::Right)
			return ColorDebug::Blue;
		return ColorDebug::Gray;
	}

	FString GetDebugString()
	{
		FString Text = GetName().ToString();
		if (ClampData.DeactivationEssenceManager != nullptr)
			Text += "\nDeactivator" + ClampData.DeactivationEssenceManager.GetName();
		if (ClampData.ClampDirection == ESanctuaryArenaSplineClampDirection::Left)
			Text += "\n Left";
		else
			Text += "\n Right";
		return Text;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		RefreshDistanceAlongSpline();
		SnapToSpline();
	}
#endif

	void RefreshSpline()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);
		check(HasValidSpline());
	}

	void RefreshDistanceAlongSpline()
	{
		if (!(HasValidSpline()))
			RefreshSpline();
		DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
	}

	bool HasValidSpline() const
	{
		if (SplineComp == nullptr)
			return false;

		if (SplineComp.SplinePoints.Num() < 2)
			return false;

		if (SplineComp.SplineLength < 1)
			return false;

		return true;
	}

	void SnapToSpline()
	{
		if (!ensure(HasValidSpline()))
			return;

		if (!ensure(DistanceAlongSpline >= 0))
			return;

		FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		SetWorldLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (AviationDevToggles::Camera::DrawCameraFocus.IsEnabled())
		{
			const FVector Location = WorldLocation;
			Debug::DrawDebugSphere(Location, 100, 12, GetDebugColor(), 3, 0.0, true);
			Debug::DrawDebugString(Location, GetDebugString(), GetDebugColor());
			if (bActiveClamp)
				Debug::DrawDebugString(Location - FVector::UpVector * 100, "active", ColorDebug::Green);
		}
#endif
	}
};

// ----------------------------------------------------------

#if EDITOR
class USanctuaryArenaSplineFollowCameraClampFocusTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryArenaClampCameraFocusSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ClampComp = Cast<USanctuaryArenaClampCameraFocusSplineComponent>(Component);
		if (ClampComp == nullptr)
			return;
		ASanctuaryArenaClampCameraFocusSpline Spline = Cast<ASanctuaryArenaClampCameraFocusSpline>(ClampComp.Owner);
		if (Spline == nullptr)
			return;
		const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(ClampComp.WorldLocation);
		DrawWireSphere(Location, 100, ClampComp.GetDebugColor(), 3, 12, true);
		DrawWorldString(ClampComp.GetDebugString(), Location, ClampComp.GetDebugColor(), 1.2, 10000.0, true, true);
	}
};

class USanctuaryArenaAddSplineFollowCameraClampFocusContextMenuExtention : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.Owner.IsA(ASanctuaryArenaClampCameraFocusSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Arena Sidescroller Camera Clamping";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddSplineClamp;
			AddSplineClamp.DelegateParam = n"AddSplineClamp";
			AddSplineClamp.Label = "Add Spline Clamp";
			AddSplineClamp.Icon = n"Icons.Plus";
			Menu.AddOption(AddSplineClamp, MenuDelegate);
		}

		ASanctuaryArenaClampCameraFocusSpline CamSpline = Cast<ASanctuaryArenaClampCameraFocusSpline>(Spline.Owner);
		if (CamSpline == nullptr)
			return;

		USanctuaryArenaClampCameraFocusSplineComponent Previous;
		USanctuaryArenaClampCameraFocusSplineComponent Next;
		float Alpha;		
		CamSpline.GetSplineClampComponents(ClickedDistance, Previous, Next, Alpha);

		if (Previous != nullptr)
		{
			FHazeContextOption DuplicatePreviousSplineClamp;
			DuplicatePreviousSplineClamp.DelegateParam = n"DuplicatePreviousSplineClamp";
			DuplicatePreviousSplineClamp.Label = "Duplicate Previous Spline Clamp";
			DuplicatePreviousSplineClamp.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicatePreviousSplineClamp, MenuDelegate);
		}

		if (Next != nullptr)
		{
			FHazeContextOption DuplicateNextSplineClamp;
			DuplicateNextSplineClamp.DelegateParam = n"DuplicateNextSplineClamp";
			DuplicateNextSplineClamp.Label = "Duplicate Next Spline Clamp";
			DuplicateNextSplineClamp.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicateNextSplineClamp, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddSplineClamp")
		{
			auto AddedSplineClamp = USanctuaryArenaClampCameraFocusSplineComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineClamp.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineClamp);
			Spline.Owner.Modify();
			return;
		}

		ASanctuaryArenaClampCameraFocusSpline CamSpline = Cast<ASanctuaryArenaClampCameraFocusSpline>(Spline.Owner);
		if (CamSpline == nullptr)
			return;

		USanctuaryArenaClampCameraFocusSplineComponent Previous;
		USanctuaryArenaClampCameraFocusSplineComponent Next;
		float Alpha;		
		CamSpline.GetSplineClampComponents(MenuClickedDistance, Previous, Next, Alpha);

		if (Previous != nullptr && OptionName == n"DuplicatePreviousSplineClamp")
		{
			auto AddedSplineClamp = USanctuaryArenaClampCameraFocusSplineComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineClamp.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineClamp);
			Spline.Owner.Modify();
			return;
		}

		if (Next != nullptr && OptionName == n"DuplicateNextSplineClamp")
		{
			auto AddedSplineClamp = USanctuaryArenaClampCameraFocusSplineComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineClamp.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineClamp);
			Spline.Owner.Modify();
			return;
		}
	}
};
#endif