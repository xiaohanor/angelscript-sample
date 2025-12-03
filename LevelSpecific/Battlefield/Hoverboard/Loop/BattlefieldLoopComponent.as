event void FBattlefieldHoverboardLoopEvent(AHazePlayerCharacter Player);
class UBattlefieldLoopComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRestrictSideways = true;

	/* How far away from the spline the hoverboard is allowed on either side */
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bRestrictSideways", EditConditionHides))
	float LoopSize = 400.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIgnoreOtherLoopCollision = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bIgnoreOtherLoopCollision, EditConditionHides))
	AHazeActor OtherLoopActor;

	UPROPERTY(Category = "Events")
	FBattlefieldHoverboardLoopEvent OnPlayerEnteredLoop;

	UPROPERTY(Category = "Events")
	FBattlefieldHoverboardLoopEvent OnPlayerExitedLoop;

	UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Owner);

	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif
	}
};

#if EDITOR
class UBattlefieldLoopComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBattlefieldLoopComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UBattlefieldLoopComponent>(Component);

		if((Comp == nullptr)
		|| (Comp.Owner == nullptr))
			return;
		
		if(!Comp.bRestrictSideways)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(Comp.Owner);

		if(SplineComp == nullptr)
			return;
		
		FVector ViewLocation = GetEditorViewLocation();
		ViewLocation +=GetEditorViewRotation().ForwardVector * (Comp.LoopSize + 1000);
		
		FSplinePosition SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ViewLocation);

		DrawCircle(SplinePos.WorldLocation, Comp.LoopSize, FLinearColor::Green, 2, SplinePos.WorldForwardVector);
		SetRenderForeground(true);
	}
}
#endif