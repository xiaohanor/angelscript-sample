event void FSkylineFlyingCarOnImpactedByFlyingCar(ASkylineFlyingCar FlyingCar, FFlyingCarOnImpactData ImpactData);
event void FSkylineFlyingCarOnImpactedByCarEnemy(ASkylineFlyingCarEnemy CarEnemy, FFlyingCarOnImpactData ImpactData);

struct FFlyingCarOnImpactData
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

	FFlyingCarOnImpactData(
		FVector InVelocity,
		FHitResult InHit)
	{
		Velocity = InVelocity;
		Component = InHit.Component;
		ImpactPoint = InHit.ImpactPoint;
		ImpactNormal = InHit.ImpactNormal;
		Normal = InHit.Normal;
	}
};

UCLASS(NotBlueprintable, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Navigation")
class USkylineFlyingCarImpactResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Should this actor be ignored for the following traces during this frames move?
	UPROPERTY(EditAnywhere, Category = "Player and Enemy Cars")
	bool bIgnoreAfterImpact = true;

	UPROPERTY(EditAnywhere, Category = "Enemy Cars", Meta = (EditCondition = "bIgnoreAfterImpact"))
	float VelocityLostOnImpact = 0.5;

	UPROPERTY()
	FSkylineFlyingCarOnImpactedByFlyingCar OnImpactedByFlyingCar;

	UPROPERTY()
	FSkylineFlyingCarOnImpactedByCarEnemy OnImpactedByCarEnemy;
};