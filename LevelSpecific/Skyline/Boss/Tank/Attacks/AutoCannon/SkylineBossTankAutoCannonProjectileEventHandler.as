struct FSkylineBossTankAutoCannonProjectileOnFireEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Direction;
	
	UPROPERTY(BlueprintReadOnly)
	int MagazinSize = 0;

	UPROPERTY(BlueprintReadOnly)
	int FiredAmount = 0;

	UPROPERTY(BlueprintReadOnly)
	float ReloadTime = 0;

	UPROPERTY(BlueprintReadOnly)
	USceneComponent Turret;
};

struct FSkylineBossTankAutoCannonProjectileOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;

	UPROPERTY(BlueprintReadOnly)
	FVector Normal;

	UPROPERTY(BlueprintReadOnly)
	FVector TraceStart;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Actor;
};

UCLASS(Abstract)
class USkylineBossTankAutoCannonProjectileEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ASkylineBossTankAutoCannonProjectile Projectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Projectile = Cast<ASkylineBossTankAutoCannonProjectile>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire(FSkylineBossTankAutoCannonProjectileOnFireEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineBossTankAutoCannonProjectileOnImpactEventData EventData)
	{
	}
};