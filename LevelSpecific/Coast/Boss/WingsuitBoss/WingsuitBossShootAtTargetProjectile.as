UCLASS(Abstract)
class AWingsuitBossShootAtTargetProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;


	FWingsuitBossShootAtTargetData TargetData;
	UWingsuitBossSettings Settings;

	void Spawn(FWingsuitBossShootAtTargetData In_TargetData, UWingsuitBossSettings In_Settings)
	{
		ActorTickEnabled = true;
		RemoveActorDisable(this);
		TargetData = In_TargetData;
		Settings = In_Settings;
		Mesh.RelativeLocation += FVector::RightVector * Settings.ShootAtTargetSpiralRadius;
		UWingsuitBossRocketEffectHandler::Trigger_OnRocketFired(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetData.TargetLocation, DeltaTime, Settings.ShootAtTargetProjectileSpeed);
		if(ActorLocation.Equals(TargetData.TargetLocation))
		{
			Explode();
			return;
		}

		ActorQuat = Math::RotatorFromAxisAndAngle(ActorForwardVector, Settings.ShootAtTargetSpiralRotationSpeed * DeltaTime).Quaternion() * ActorQuat;
	}

	void Explode()
	{
		if(TargetData.ResponseActor != nullptr)
		{
			auto Response = UWingsuitBossShootAtTargetResponseComponent::Get(TargetData.ResponseActor);
			if(Response != nullptr)
				Response.OnImpact.Broadcast();
		}

		Timer::SetTimer(this, n"DisableTheActor", 2, false);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionEffect, ActorLocation);
		ActorTickEnabled = false;
		UWingsuitBossRocketEffectHandler::Trigger_OnRocketExploded(this);
	}

	UFUNCTION()
	void DisableTheActor()
	{
		AddActorDisable(this);
	}
}