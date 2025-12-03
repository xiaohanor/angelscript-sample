struct FGravityBikeSplineCameraSettings
{
	float IdealDistance;
	float FOV;
	
	FGravityBikeSplineCameraSettings(UGravityBikeSplineCameraLookComponent LookComp)
	{
		IdealDistance = LookComp.bOverrideIdealDistance ? LookComp.IdealDistance : GravityBikeSpline::DefaultIdealDistance;
		FOV = LookComp.bOverrideFOV ? LookComp.FieldOfView : GravityBikeSpline::DefaultFOV;
	}

	FGravityBikeSplineCameraSettings(UGravityBikeSplineCameraLookComponent Previous, UGravityBikeSplineCameraLookComponent Next, float Alpha)
	{
		const float PreviousIdealDistance = Previous.bOverrideIdealDistance ? Previous.IdealDistance : GravityBikeSpline::DefaultIdealDistance;
		const float PreviousFOV = Previous.bOverrideFOV ? Previous.FieldOfView : GravityBikeSpline::DefaultFOV;

		const float NextIdealDistance = Next.bOverrideIdealDistance ? Next.IdealDistance : GravityBikeSpline::DefaultIdealDistance;
		const float NextFOV = Next.bOverrideFOV ? Next.FieldOfView : GravityBikeSpline::DefaultFOV;

		IdealDistance = Math::Lerp(PreviousIdealDistance, NextIdealDistance, Alpha);
		FOV = Math::Lerp(PreviousFOV, NextFOV, Alpha);
	}
};

UCLASS(NotBlueprintable)
class UGravityBikeSplineCameraLookSplineComponent : UActorComponent
{
	UPROPERTY(Transient)
	TArray<UGravityBikeSplineCameraLookComponent> LookComponents;

	UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);
		check(SplineComp != nullptr);

		GetAndSortLookComponents();
	}

	void GetAndSortLookComponents()
	{
		LookComponents.Reset();
		Owner.GetComponentsByClass(LookComponents);
		LookComponents.Sort();
	}

	// @return False if only one or no components are valid, thus not making interpolation possible
	bool GetCameraLookComponents(float DistanceAlongSpline, UGravityBikeSplineCameraLookComponent&out Previous, UGravityBikeSplineCameraLookComponent&out Next, float&out Alpha) const
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
			Previous = LookComponents[0];
			Next = LookComponents[1];
			Alpha = 0;
			return true;
		}

		if(DistanceAlongSpline > SplineComp.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > LookComponents[LookComponents.Num() - 1].DistanceAlongSpline)
		{
			Previous = LookComponents[LookComponents.Num() - 2];
			Next = LookComponents[LookComponents.Num() - 1];
			Alpha = 1;
			return true;
		}

		// FB TODO: Faster search
		for(int i = 1; i < LookComponents.Num(); i++)
		{
			UGravityBikeSplineCameraLookComponent PreviousComp = LookComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			UGravityBikeSplineCameraLookComponent NextComp = LookComponents[i];
			if(NextComp.DistanceAlongSpline < DistanceAlongSpline)
				continue;
			
			Previous = PreviousComp;
			Next = NextComp;

			Alpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousComp.DistanceAlongSpline, NextComp.DistanceAlongSpline);
			Alpha = Math::SmoothStep(0, 1, Alpha);
			return true;
		}

		check(false);
		return false;
	}

	FQuat GetCameraRotationAtDistanceAlongSpline(float DistanceAlongSpline, float LeadDistance) const
	{
		if(LookComponents.Num() == 0)
			return SplineComp.GetWorldRotationAtSplineDistance(DistanceAlongSpline + LeadDistance);

		if(LookComponents.Num() == 1 || DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < LookComponents[0].DistanceAlongSpline)
			return LookComponents[0].ComponentQuat;

		if(DistanceAlongSpline > SplineComp.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > LookComponents[LookComponents.Num() - 1].DistanceAlongSpline)
			return LookComponents[LookComponents.Num() - 1].ComponentQuat;

		UGravityBikeSplineCameraLookComponent Previous;
		UGravityBikeSplineCameraLookComponent Next;
		float Alpha;
		bool bSuccess = GetCameraLookComponents(DistanceAlongSpline, Previous, Next, Alpha);
		check(bSuccess);

		return FQuat::Slerp(Previous.ComponentQuat, Next.ComponentQuat, Alpha);
	}

	TOptional<FGravityBikeSplineCameraSettings> GetCameraSettingsDistanceAlongSpline(float DistanceAlongSpline)
	{
		TOptional<FGravityBikeSplineCameraSettings> Result;

		UGravityBikeSplineCameraLookComponent Previous;
		UGravityBikeSplineCameraLookComponent Next;
		float Alpha;
		if(GetCameraLookComponents(DistanceAlongSpline, Previous, Next, Alpha))
		{
			Result.Set(FGravityBikeSplineCameraSettings(Previous, Next, Alpha));
		}
		else
		{
			if(Previous == nullptr && Next == nullptr)
				return Result;

			if(Previous != nullptr)
				Result.Set(FGravityBikeSplineCameraSettings(Previous));

			if(Next != nullptr)
				Result.Set(FGravityBikeSplineCameraSettings(Next));
		}

		return Result;
	}
};

#if EDITOR
class UGravityBikeSplineCameraLookSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(UGravityBikeSplineCameraLookSplineComponent::Get(Spline.Owner) == nullptr)
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Gravity Bike Camera Look";
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
			AddCameraLook.Tooltip = "";
			Menu.AddOption(AddCameraLook, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(
		FHazeContextOption Option,
		UHazeSplineComponent Spline,
	    UHazeSplineSelection Selection,
		float MenuClickedDistance,
	    int MenuClickedPoint
	) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddCameraLook")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineCameraLookComponent);
		}
	}
};
#endif