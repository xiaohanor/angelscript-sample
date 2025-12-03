event void FGravityBikeSplineOnImpact(AHazeActor Actor, FGravityBikeSplineOnImpactData Data);

struct FGravityBikeSplineImpactResponseComponentAndData
{
	UPROPERTY()
	UGravityBikeSplineImpactResponseComponent ResponseComp;

	UPROPERTY()
	FGravityBikeSplineOnImpactData ImpactData;
}

struct FGravityBikeSplineOnImpactData
{
	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	UPrimitiveComponent Component;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	FVector Normal;

	FGravityBikeSplineOnImpactData(
		FVector InVelocity,
		FHitResult InHitResult,
	)
	{
		Velocity = InVelocity;
		Component = InHitResult.Component;
		ImpactPoint = InHitResult.ImpactPoint;
		ImpactNormal = InHitResult.ImpactNormal;
		Normal = InHitResult.Normal;
	}
}

UCLASS(NotBlueprintable)
class UGravityBikeSplineImpactResponseComponent : UActorComponent
{
	// Should this actor be ignored for the following traces during this frames move?
	UPROPERTY(EditAnywhere)
	bool bIgnoreAfterImpact = true;

	// The gravity bike traces forward to prepare for landings while moving, if this is true, then it will be a valid surface to align towards
	UPROPERTY(EditAnywhere)
	bool bAllowBikeToAlign = false;

	UPROPERTY(EditAnywhere)
	float PitchImpulseMultiplier = 1.0;

	UPROPERTY()
	FGravityBikeSplineOnImpact OnImpact;
};