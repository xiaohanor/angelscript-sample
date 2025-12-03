UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers Trigger", ComponentWrapperClass, Meta = (HighlightPlacement = "110"))
class AGravityBikeSplineRedirectVelocityVolume : AGravityBikeSplineTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor::Teal);
	default bOnlyTriggerWhenGrounded = false;

	UPROPERTY(DefaultComponent)
	UArrowComponent RedirectVelocityDirectionComp;
	default RedirectVelocityDirectionComp.ArrowSize = 30;
	default RedirectVelocityDirectionComp.ArrowColor = FLinearColor::Purple;

	UPROPERTY(EditInstanceOnly, Category = "Redirect Velocity")
	bool bUseDuration = false;

	UPROPERTY(EditInstanceOnly, Category = "Redirect Velocity", Meta = (EditCondition = "!bUseDuration", EditConditionHides))
	float RotateSpeed = 1;

	UPROPERTY(EditInstanceOnly, Category = "Redirect Velocity", Meta = (EditCondition = "!bUseDuration", EditConditionHides))
	float FadeInDuration = 0.3;

	UPROPERTY(EditInstanceOnly, Category = "Redirect Velocity", Meta = (EditCondition = "bUseDuration", EditConditionHides))
	float RotateDuration = 2;

	UPROPERTY(EditInstanceOnly, Category = "Redirect Velocity", Meta = (EditCondition = "bUseDuration", EditConditionHides))
	UCurveFloat RotateDurationAlphaCurve = Curve::SmoothCurveZeroToOne;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnGravityBikeEnter.AddUFunction(this, n"OnEnter");
		OnGravityBikeExit.AddUFunction(this, n"OnExit");
	}

	UFUNCTION()
	private void OnEnter(AGravityBikeSpline GravityBike, UGravityBikeSplineTriggerComponent TriggerComp)
	{
		auto RedirectVelocityComp = UGravityBikeSplineRedirectVelocityComponent::Get(GravityBike);
		if(RedirectVelocityComp == nullptr)
			return;

		RedirectVelocityComp.CurrentRedirectVelocityVolumes.AddUnique(this);
	}

	UFUNCTION()
	private void OnExit(AGravityBikeSpline GravityBike, UGravityBikeSplineTriggerComponent TriggerComp)
	{
		auto RedirectVelocityComp = UGravityBikeSplineRedirectVelocityComponent::Get(GravityBike);
		if(RedirectVelocityComp == nullptr)
			return;

		RedirectVelocityComp.CurrentRedirectVelocityVolumes.RemoveSingle(this);
	}
};