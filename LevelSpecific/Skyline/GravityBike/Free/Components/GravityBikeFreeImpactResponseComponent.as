event void FGravityBikeFreeOnImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data);

struct FGravityBikeFreeImpactResponseComponentAndData
{
	UPROPERTY()
	UGravityBikeFreeImpactResponseComponent ResponseComp;

	UPROPERTY()
	FGravityBikeFreeOnImpactData ImpactData;
}

struct FGravityBikeFreeOnImpactData
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

	FGravityBikeFreeOnImpactData(
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
class UGravityBikeFreeImpactResponseComponent : UActorComponent
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
	FGravityBikeFreeOnImpact OnImpact;
};