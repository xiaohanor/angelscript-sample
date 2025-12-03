event void FSummitRollRailEvent();

class USummitTeenDragonRollRailSplineComponent : USceneComponent
{
	// How far away from the spline that is considered "On it"
	UPROPERTY(EditAnywhere, Category = "Settings")
	float SplineSize = 150.0;

	// How far away from the spline you can be before it starts to check it
	UPROPERTY(EditAnywhere, Category = "Settings")
	float SplineBoundsDistance = 10000.0;

	/** Settings to override per rail */
	UPROPERTY(EditAnywhere, Category = "Settings")
	UTeenDragonRollRailSettings OverridingRailSettings;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRequireRollToStart = true;

	UPROPERTY(BlueprintReadOnly)
	FSummitRollRailEvent OnRailEntered;

	UPROPERTY(BlueprintReadOnly)
	FSummitRollRailEvent OnRailExited;

	UHazeSplineComponent SplineComp;
	UTeenDragonRollRailComponent RollRailComp;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = Audio)
	UHazeAudioEvent RollRailAudioEvent;

	bool bIsEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Owner);

		devCheck(SplineComp != nullptr, f"{Owner.Name} has a SummitTeenDragonRollRailSplineComponent, but no spline component");

	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RollRailComp == nullptr)
			RollRailComp = UTeenDragonRollRailComponent::Get(Game::GetZoe());
		
		float DistSqrd = WorldLocation.DistSquared(RollRailComp.Owner.ActorLocation);
		if(DistSqrd <= Math::Square(SplineBoundsDistance))
		{
			if(!RollRailComp.RollRailsInRange.Contains(this))
				RollRailComp.RollRailsInRange.Add(this);
		}
		else
		{
			if(RollRailComp.RollRailsInRange.Contains(this))
				RollRailComp.RollRailsInRange.RemoveSingleSwap(this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void ToggleRailActive(bool bActivate)
	{
		bIsEnabled = bActivate;

		if(bActivate)
		{
			SetComponentTickEnabled(true);
		}
		else
		{
			SetComponentTickEnabled(false);
			if ((RollRailComp != nullptr) && RollRailComp.RollRailsInRange.Contains(this))
				RollRailComp.RollRailsInRange.RemoveSingleSwap(this);
		}
	}

	/* Tries to place the component in the middle of the spline. */
	UFUNCTION(CallInEditor, Category = "Setup")
	void UpdateSplineBounds()
	{
		FVector BoundsCenter;
		FVector BoundsExtent;
		Owner.GetActorBounds(true, BoundsCenter, BoundsExtent, true);
		SetWorldLocation(BoundsCenter);

		SplineBoundsDistance = BoundsExtent.Size() + 5000;
	}
};

#if EDITOR
class USummitTeenDragonRollRailSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitTeenDragonRollRailSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USummitTeenDragonRollRailSplineComponent Comp = Cast<USummitTeenDragonRollRailSplineComponent>(Component);

		if(!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
			 return;

		SetRenderForeground(false);
		DrawWireCylinder(Comp.WorldLocation, Comp.WorldRotation, FLinearColor::Green, Comp.SplineBoundsDistance, 80, 50, 20, false);
	}
}
#endif