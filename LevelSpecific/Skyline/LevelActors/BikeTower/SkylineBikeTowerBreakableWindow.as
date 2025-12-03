class ASkylineBikeTowerBreakableWindow : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	USkylineBossTankAutoCannonProjectileResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	TArray<UBreakableComponent> Breakables;

	float BreakForce = 25000.0; // 12000.0
	float BreakRadius = 1000.0; // 1000.0
	float BreakScatter = 0.3; // 0.2
	float Gravity = -980 * 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(Breakables);

		for (auto Breakable : Breakables)
		{
			Breakable.Gravity = FVector::UpVector * Gravity;
			Breakable.SetMaterial(0, Material);
			Breakable.LoadFromPreset();
		}

		ResponseComp.OnProjectileImpact.AddUFunction(this, n"HandleProjectileImpact");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GetComponentsByClass(Breakables);
		for (auto Breakable : Breakables)
		{
			Breakable.Gravity = FVector::UpVector * Gravity;
			Breakable.SetMaterial(0, Material);
			Breakable.ConstructionScript_Hack();
		}
	}

	UFUNCTION()
	private void HandleProjectileImpact(FHitResult HitResult, FVector Velocity)
	{
		for (auto Breakable : Breakables)
		{
			if (Breakable != HitResult.Component)
				continue;

			FVector BreakLocation = HitResult.Location - Velocity.SafeNormal * 400.0;
			FVector BreakDirection = Math::Lerp(Velocity.SafeNormal, ActorForwardVector, 0.5);

			float BreakRadiusScaled = Math::RandRange(BreakRadius * 0.8, BreakRadius * 1.2);
			float BreakForceScaled = Math::RandRange(BreakForce * 0.5, BreakForce * 1.2);

//			Debug::DrawDebugSphere(BreakLocation, BreakRadiusScaled, 24, FLinearColor::Red, 20.0, 4.0);
//			Debug::DrawDebugLine(BreakLocation, BreakLocation + BreakDirection * BreakForceScaled, FLinearColor::Red, 20.0, 4.0);

			Breakable.BreakAt(BreakLocation, BreakRadiusScaled, BreakDirection * BreakForceScaled, BreakScatter);
		}
	}
};