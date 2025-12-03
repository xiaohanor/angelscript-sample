
// When there are detector components, the actors responsible for shooting relevant projectiles should 
// have a Notifier component, which lets the response components know when projectiles are near them.
class UProjectileProximityManagerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private TArray<AActor> Projectiles;
	private TArray<UProjectileProximityDetectorComponentBase> Detectors;

	void RegisterProximityDetector(UProjectileProximityDetectorComponentBase Detector)
	{
		Detectors.AddUnique(Detector);
		if (Projectiles.Num() > 0)
			SetComponentTickEnabled(true);
	}

	void UnregisterProximityDetector(UProjectileProximityDetectorComponentBase Detector)
	{
		Detectors.RemoveSwap(Detector);
		if (Detectors.Num() == 0)
			SetComponentTickEnabled(false);
	}

	void RegisterProjectile(AActor Projectile)
	{
		Projectiles.AddUnique(Projectile);
		if (Detectors.Num() > 0)
			SetComponentTickEnabled(true);
	}

	void UnregisterProjectile(AActor Projectile)
	{
		Projectiles.RemoveSwap(Projectile);
		if (Projectiles.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Optimize as needed!
		for (AActor Projectile : Projectiles)
		{
			for (UProjectileProximityDetectorComponentBase Detector : Detectors)
			{
				Detector.CheckProximity(Projectile);
			}
		}
	}
}