UCLASS(Abstract)
class AGravityBikeSplineBreakable : ABreakableActor
{
	default BreakableComponent.CullDistanceMultiplier = 5;
	default DisableComp.AutoDisableRange = 20000;
	
	UPROPERTY(DefaultComponent)
	UGravityBikeSplineImpactResponseComponent ImpactResponseComp;

	UPROPERTY(EditInstanceOnly)
	float CamperaImpulseForce = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(GravityBikeSpline::GetDriverPlayer());

		Super::BeginPlay();
		ImpactResponseComp.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(AHazeActor Actor, FGravityBikeSplineOnImpactData Data)
	{
		if(!Actor.HasControl())
			return;

		if(BreakableComponent.Broken)
			return;

		const FVector RelativeImpactPoint = BreakableComponent.WorldTransform.InverseTransformPosition(Data.ImpactPoint);
		const FVector RelativeImpactNormal = BreakableComponent.WorldTransform.InverseTransformVector(Data.ImpactNormal);
		CrumbOnImpact(Data.Velocity, RelativeImpactPoint, RelativeImpactNormal);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnImpact(FVector Velocity, FVector RelativeImpactPoint, FVector RelativeImpactNormal)
	{
		if(BreakableComponent.Broken)
			return;

		PrintToScreenScaled("Break" + Velocity, 3.0);

		const FVector ImpactPoint = BreakableComponent.WorldTransform.TransformPosition(RelativeImpactPoint);
		const FVector ImpactNormal = BreakableComponent.WorldTransform.TransformVector(RelativeImpactNormal);
		BreakableComponent.BreakAt(ImpactPoint, 500, Velocity * 10, 0.2);

		FHazeCameraImpulse Impulse;
		Impulse.WorldSpaceImpulse = ImpactNormal * CamperaImpulseForce;
		GravityBikeSpline::GetDriverPlayer().ApplyCameraImpulse(Impulse, this);
	}
};