enum EGravityBikeBladeTargetType
{
	// Target is a surface with a spline.
	Surface,

	// Move around the circumference of a barrel, then target a new surface after a duration.
	Barrel,
};

UCLASS(NotBlueprintable, HideCategories = "Rendering Activation Cooking Tags LOD AssetUserData Navigation")
class UGravityBikeBladeTargetComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target")
	EGravityBikeBladeTargetType Type = EGravityBikeBladeTargetType::Surface;
	
	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target|Surface", Meta = (EditCondition = "Type == EGravityBikeBladeTargetType::Surface"))
	AGravityBikeSplineActor SurfaceSpline;

	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target|Barrel", Meta = (EditCondition = "Type == EGravityBikeBladeTargetType::Barrel"))
	AGravityBikeBladeSurface AfterBarrelSurface;

	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target")
	UCurveFloat GrappleTimeDilationCurve = GravityBikeBladeSurfaceTimeDilationCurve;

	//UPROPERTY(EditAnywhere, Category = "Gravity Blade Target")
	// float BladeThrowDuration = 1;

	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target")
	float BladeGrappleDuration = 1;

	UPROPERTY(EditAnywhere, Category = "Gravity Blade Target", Meta = (MakeEditWidget))
	FVector VisualOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		switch(Type)
		{
			case EGravityBikeBladeTargetType::Surface:
			{
				check(SurfaceSpline != nullptr);
				break;
			}

			case EGravityBikeBladeTargetType::Barrel:
			{
				check(AfterBarrelSurface != nullptr);
				break;
			}
		}
	}

	FVector GetVisualLocation() const
	{
		return WorldTransform.TransformPosition(VisualOffset);
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Gravity Blade Target")
	private void SelectGravityTrigger()
	{
		TArray<AGravityBikeBladeGravityTrigger> Actors = Editor::GetAllEditorWorldActorsOfClass(AGravityBikeBladeGravityTrigger);
		for(auto Actor : Actors)
		{
			AGravityBikeBladeGravityTrigger Trigger = Cast<AGravityBikeBladeGravityTrigger>(Actor);
			if(Trigger.GravityBladeTargetActor == Owner)
			{
				Editor::SelectActor(Trigger);
				return;
			}
		}
	}
#endif
};

#if EDITOR
class UGravityBikeBladeTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeBladeTargetComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto TargetComp = Cast<UGravityBikeBladeTargetComponent>(InComponent);
		if(TargetComp == nullptr)
			return;

		SetRenderForeground(false);

		SetHitProxy(n"Target", EVisualizerCursor::Hand);

		FLinearColor Color = FLinearColor::Red;
		if(Editor::IsComponentSelected(TargetComp))
			Color = FLinearColor::Yellow;

		DrawWireSphere(TargetComp.WorldLocation, GravityBikeSpline::Radius, Color, 10, 16, true);
		DrawArrow(TargetComp.WorldLocation, TargetComp.WorldLocation + TargetComp.ForwardVector * 2000.0, Color, 200, 10, true);
		
		DrawWireSphere(TargetComp.GetVisualLocation(), GravityBikeSpline::Radius, FLinearColor::Green, 10, 16, true);
	}
	
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(
		FName HitProxy,
		FVector ClickOrigin,
		FVector ClickDirection,
		FKey Key,
	    EInputEvent Event)
	{
		auto TargetComp = Cast<UGravityBikeBladeTargetComponent>(EditingComponent);
		if(TargetComp == nullptr)
			return false;

		if(HitProxy == n"Target")
		{
			Editor::SelectComponent(TargetComp);
			return true;
		}

		return false;
	}
};
#endif