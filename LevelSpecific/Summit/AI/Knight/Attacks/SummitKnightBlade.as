class USummitKnightBladeComponent : UStaticMeshComponent
 {
	default CollisionProfileName = n"NoCollision";
	default bCanEverAffectNavigation = false;
	default AddTag(n"SkipAcidOverlayMaterial");

	ASummitKnightBladeRollSplineActor RollSpline;

	USummitTeenDragonRollRailSplineComponent SpawnRollSpline()
	{
		if (RollSpline != nullptr)
			return RollSpline.RollComp;

		// Spawn splines to roll up blade
		if (AttachSocketName == n"LeftAttach")
			RollSpline = SpawnActor(ASummitKnightBladeRollSplineActorLeft, bDeferredSpawn = true);
		else
			RollSpline = SpawnActor(ASummitKnightBladeRollSplineActor, bDeferredSpawn = true);
		if (ensure(RollSpline != nullptr))
		{
			RollSpline = SpawnActor(ASummitKnightBladeRollSplineActor, bDeferredSpawn = true);
			RollSpline.MakeNetworked(this, n"Rollspline");
			FinishSpawningActor(RollSpline);
			DisableRollSpline();
			return RollSpline.RollComp;
		}
		return nullptr;
	}

	void Equip()
	{
		SetHiddenInGame(false);
	}

	void Unequip()
	{
		SetHiddenInGame(true);
		DisableRollSpline();
	}

	void DisableRollSpline()
	{
		// HACK: Can't disable yet, place this in a galaxy far, far away...
		//RollSpline.RollComp.ToggleRailActive(false);
		if (RollSpline != nullptr)
			RollSpline.ActorLocation = FVector(BIG_NUMBER);
	}

	void EnableRollSpline()
	{
		//RollSpline.RollComp.ToggleRailActive(true);
		if (RollSpline != nullptr)
			RollSpline.ActorTransform = WorldTransform;
	}

	FVector GetTipLocation() const property
	{
		return WorldTransform.TransformPosition(FVector(0.0, 1900.0, 0.0));
	}

	FVector GetHiltLocation() const property
	{
		return WorldTransform.TransformPosition(FVector(0.0, -300.0, 0.0));
	}

	float GetBladeLength() const property
	{
		return HiltLocation.Distance(TipLocation);
	}
 }

#if EDITOR
class USummitKnightBladeComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitKnightBladeComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USummitKnightBladeComponent BladeComp = Cast<USummitKnightBladeComponent>(Component);
		if (BladeComp == nullptr)
			return;
		UObject CDO = ASummitKnightBladeRollSplineActor.GetDefaultObject();
		if (BladeComp.AttachSocketName == n"LeftAttach")
			CDO = ASummitKnightBladeRollSplineActorLeft.GetDefaultObject();
		UHazeSplineComponent Spline = UHazeSplineComponent::Get(Cast<AActor>(CDO));
		if (Spline == nullptr)
			return;
		for (int i = 1; i < Spline.SplinePoints.Num(); i++)
		{
			FVector PrevLoc = BladeComp.WorldTransform.TransformPosition(Spline.SplinePoints[i - 1].RelativeLocation);
			FVector NextLoc = BladeComp.WorldTransform.TransformPosition(Spline.SplinePoints[i].RelativeLocation);
			DrawLine(PrevLoc, NextLoc, FLinearColor::Yellow, 20.0);
		}
	}
}
#endif

class ASummitKnightBladeRollSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitTeenDragonRollRailSplineComponent RollComp;
	default RollComp.SplineSize = 500.0;
	default RollComp.OverridingRailSettings = SummitKnightBladeRollSplineSettings;
	
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.SplinePoints.SetNum(3);
	default Spline.SplinePoints[0].RelativeLocation = FVector(0.0, -420.0, -5.0);
	default Spline.SplinePoints[1].RelativeLocation = FVector(25.0, -350.0, 5.0);
	default Spline.SplinePoints[2].RelativeLocation = FVector(25.0, -20.0, 0.0);
}

class ASummitKnightBladeRollSplineActorLeft : ASummitKnightBladeRollSplineActor
{
	default Spline.SplinePoints[0].RelativeLocation = FVector(0.0, -420.0, 0.0);
	default Spline.SplinePoints[1].RelativeLocation = FVector(25.0, -350.0, -5.0);
	default Spline.SplinePoints[2].RelativeLocation = FVector(30.0, -20.0, 0.0);
}
 
asset SummitKnightBladeRollSplineSettings of UTeenDragonRollRailSettings
{
	MinSpeed = 400.0;
	MaxSpeed = 600.0;
}

namespace SummitKnightBlade
{
	USummitKnightBladeComponent GetLeft(AActor Owner)
	{
		if (Owner == nullptr)
			return nullptr;

		TArray<USummitKnightBladeComponent> Blades;
		Owner.GetComponentsByClass(Blades);
		for (auto Blade : Blades)
		{
			if (Blade.AttachSocketName == n"LeftAttach")
				return Blade;
		}
		return nullptr;		
	}

	USummitKnightBladeComponent GetRight(AActor Owner)
	{
		if (Owner == nullptr)
			return nullptr;

		TArray<USummitKnightBladeComponent> Blades;
		Owner.GetComponentsByClass(Blades);
		for (auto Blade : Blades)
		{
			if (Blade.AttachSocketName == n"RightAttach")
				return Blade;
		}
		return nullptr;		
	}
}

