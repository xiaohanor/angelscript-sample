UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers Trigger", ComponentWrapperClass, Meta = (HighlightPlacement = "110"))
class AGravityBikeSplineAutoSteerVolume : AGravityBikeSplineTrigger
{
	UPROPERTY(DefaultComponent)
	UArrowComponent AutoSteerDirectionComp;
	default AutoSteerDirectionComp.ArrowColor = FLinearColor::Teal;
	default AutoSteerDirectionComp.ArrowSize = 50;
	default AutoSteerDirectionComp.bAbsoluteScale = true;

	/**
	 * How strong the auto steer should be. 1 means that it could fully override player input.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Auto Steer", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float AutoSteerInfluence = 0.7;

	/**
	 * How much angle difference is needed for full auto steer input.
	 */
	UPROPERTY(EditInstanceOnly, Category = "Auto Steer", Meta = (ClampMin = "0.0", ClampMax = "45.0"))
	float AutoSteerThresholdDegrees = 20;

	UPROPERTY(EditInstanceOnly, Category = "Auto Steer")
	bool bApplyOnlyWhileAirborne = false;

	UPROPERTY(EditInstanceOnly, Category = "Auto Steer")
	bool bClearOnlyWhenGrounded = true;

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
		auto AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
		if(AutoSteerComp == nullptr)
			return;

		AutoSteerComp.CurrentAutoSteerVolumes.Add(this);
	}

	UFUNCTION()
	private void OnExit(AGravityBikeSpline GravityBike, UGravityBikeSplineTriggerComponent TriggerComp)
	{
		auto AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
		if(AutoSteerComp == nullptr)
			return;

		AutoSteerComp.CurrentAutoSteerVolumes.RemoveSingle(this);
	}
};