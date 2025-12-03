UCLASS(Abstract)
class UIslandShieldotronMortarProjectileEventHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTargetTelegraph(FIslandShieldotronMortarProjectileOnTargetTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopTargetTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FIslandShieldotronMortarProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPeakTrajectory() {}

	// Hit some object or non-player actor.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FIslandShieldotronMortarProjectileOnHitEventData Data) {}

	// Impact with player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer(FIslandShieldotronMortarProjectileOnHitPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpire(FIslandShieldotronMortarProjectileOnHitEventData Data) {}
}

struct FIslandShieldotronMortarProjectileOnTargetTelegraphEventData
{
	UPROPERTY()
	FVector TargetWorldLocation;
	
	UPROPERTY()
	AActor HitGroundActor;

	FIslandShieldotronMortarProjectileOnTargetTelegraphEventData(FVector InTargetWorldLocation, AActor HitGround)
	{
		TargetWorldLocation = InTargetWorldLocation;
		HitGroundActor = HitGround;
	}
}

struct FIslandShieldotronMortarProjectileOnLaunchEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector MuzzleLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector LaunchDir;


	FIslandShieldotronMortarProjectileOnLaunchEventData(FVector InMuzzleLocation, FVector InLaunchDir)
	{
		MuzzleLocation = InMuzzleLocation;
		LaunchDir = InLaunchDir;
	}
}

struct FIslandShieldotronMortarProjectileOnHitEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	AActor HitGroundActor;

	FIslandShieldotronMortarProjectileOnHitEventData(FVector InLocation, FVector InImpactNormal, AActor _GroundActor)
	{
		Location = InLocation;
		ImpactNormal = InImpactNormal;
		HitGroundActor = _GroundActor;
	}
}

struct FIslandShieldotronMortarProjectileOnHitPlayerEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactDirection;
	
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter HitPlayer;

	FIslandShieldotronMortarProjectileOnHitPlayerEventData(FVector InLocation, FVector InImpactDirection, AHazePlayerCharacter InHitPlayer)
	{
		Location = InLocation;
		ImpactDirection = InImpactDirection;
		HitPlayer = InHitPlayer;
	}
}

