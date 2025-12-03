event void FOnGravityBikeBladeGravityTriggerStartPrimary();
event void FOnGravityBikeBladeGravityTriggerStopPrimary();
event void FOnGravityBikeBladeGravityTriggerStartThrow();
event void FOnGravityBikeBladeGravityTriggerStopThrow();
event void FOnGravityBikeBladeGravityTriggerStartGravityChange();
event void FOnGravityBikeBladeGravityTriggerStopGravityChange();

UCLASS(NotBlueprintable)
class AGravityBikeBladeGravityTrigger : APlayerTrigger
{
	access Target = private, UGravityBikeBladeTargetComponent, UGravityBikeBladeGravityTriggerVisualComponentVisualizer;

	default bTriggerForZoe = false;
	default bTriggerLocally = true;
	default BrushColor = FLinearColor::Green;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGravityBikeBladeGravityTriggerVisualComponent VisualComp;
#endif

	/**
	 * The gravity blade target we are targeting when in this trigger
	 */
	UPROPERTY(EditInstanceOnly, Category = "Gravity Blade Trigger")
	access:Target
	AHazeActor GravityBladeTargetActor;

	UPROPERTY(EditAnywhere, Category = "Gravity Blade Trigger")
	FTimeDilationEffect TimeDilationEffect;
	default TimeDilationEffect.TimeDilation = 0.2;
	default TimeDilationEffect.BlendInDurationInRealTime = 1.5;
	default TimeDilationEffect.BlendOutDurationInRealTime = 0.1;

	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStartPrimary OnStartPrimary;
	
	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStopPrimary OnStopPrimary;

	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStartThrow OnStartThrow;

	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStopThrow OnStopThrow;

	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStartGravityChange OnStartGravityChange;
	
	UPROPERTY()
	FOnGravityBikeBladeGravityTriggerStopGravityChange OnStopGravityChange;

	UGravityBikeBladeTargetComponent TargetComp;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(GravityBladeTargetActor != nullptr && UGravityBikeBladeTargetComponent::Get(GravityBladeTargetActor) == nullptr)
			GravityBladeTargetActor = nullptr;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");

		if(GravityBladeTargetActor != nullptr)
		{
			TargetComp = UGravityBikeBladeTargetComponent::Get(GravityBladeTargetActor);
			check(TargetComp != nullptr);
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UGravityBikeBladePlayerComponent BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
		if(BladeComp == nullptr)
			return;

		BladeComp.GravityTriggers.AddUnique(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UGravityBikeBladePlayerComponent BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
		if(BladeComp == nullptr)
			return;

		BladeComp.GravityTriggers.Remove(this);
	}

	bool IsCurrentGravitySpline() const
	{
		if(TargetComp == nullptr)
			return false;

		return TargetComp.SurfaceSpline == GravityBikeSpline::GetGravityBikeSpline();
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeBladeGravityTriggerVisualComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	bool bDrawArrow = true;
};

class UGravityBikeBladeGravityTriggerVisualComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeBladeGravityTriggerVisualComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		AGravityBikeBladeGravityTrigger Trigger = Cast<AGravityBikeBladeGravityTrigger>(Component.Owner);
		if(Trigger == nullptr)
			return;
		
		auto TargetComp = UGravityBikeBladeTargetComponent::Get(Trigger.GravityBladeTargetActor);

		if(TargetComp == nullptr)
		{
			FVector Origin;
			FVector Extents;
			Trigger.GetActorBounds(false, Origin, Extents);
			DrawWireBox(Origin, Extents, FQuat::Identity, FLinearColor::Red, 10, true);
			return;
		}

		DrawArrow(Trigger.ActorLocation, TargetComp.WorldLocation, FLinearColor::Purple, 1000, 10, true);

		if(TargetComp.SurfaceSpline != nullptr)
		{
			const float Increments = 5000;
			const FVector Start = Trigger.ActorLocation;
			float SplineDistance = 0;
			while(SplineDistance < TargetComp.SurfaceSpline.SplineComp.SplineLength)
			{
				const FVector End = TargetComp.SurfaceSpline.SplineComp.GetWorldLocationAtSplineDistance(SplineDistance);
				const float Distance = Start.Distance(End);
				DrawArrow(Trigger.ActorLocation, End, FLinearColor::LucBlue, Distance / 50, 1, true);
				SplineDistance += Increments;
			}
		}
	}
};
#endif