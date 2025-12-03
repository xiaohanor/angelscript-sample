event void FOnHurt();
delegate void FOnMeltdownBossHealthThreshold();
event void FOnHitByGlitch();

namespace MeltdownBoss
{
	namespace DevToggles
	{
		const FHazeDevToggleBool InvincibleBoss;
	}
}

class AMeltdownBoss : AHazeCharacter
{
	default CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	UPROPERTY(DefaultComponent)
	UMeltdownBossHealthComponent HealthComponent;
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponseComp;
	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;
	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	FOnMeltdownBossHealthThreshold ThresholdReached;
	float HealthThreshold = -1.0;
	bool bThresholdActive = false;

	UPROPERTY()
	FOnHurt OnHurtAnimDone;

	UPROPERTY()
	FOnHitByGlitch GlitchHit();

	bool bIsThirdPhase;

	AHazePlayerCharacter TargetPlayer;

	FHazeAcceleratedQuat AcceleratedRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GlitchResponseComp.OnGlitchHit.AddUFunction(this, n"OnGlitchHit");
		MeltdownBoss::DevToggles::InvincibleBoss.MakeVisible();
	}

	UFUNCTION(BlueprintCallable)
	void ThirdPhase()
	{
			TargetPlayer = Game::Zoe;
			bIsThirdPhase = true;
	}

	UFUNCTION(BlueprintPure)
	float GetBossHealth()
	{
		return HealthComponent.CurrentHealth;
	}
	

	UFUNCTION()
	private void OnGlitchHit(FMeltdownGlitchImpact Impact)
	{
		auto Settings = UMeltdownGlitchShootingSettings::GetSettings(Impact.FiringPlayer);
		if (!MeltdownBoss::DevToggles::InvincibleBoss.IsEnabled())
			HealthComponent.Damage(Impact.Damage);
		HitReact();
		HitReactWithParams(Impact);
		GlitchHit.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void HitReactWithParams(FMeltdownGlitchImpact Impact)
	{
	}

	UFUNCTION(BlueprintEvent)
	void HitReact()
	{
	}

	UFUNCTION()
	void SetCurrentBossHealth(float Health)
	{
		HealthComponent.SetCurrentHealth(Health);
	}

	UFUNCTION(Meta = (UseExecPins))
	void SetHealthThreshold(float Threshold, FOnMeltdownBossHealthThreshold OnThresholdReached)
	{
		HealthThreshold = Threshold;
		ThresholdReached = OnThresholdReached;
		bThresholdActive = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HealthThreshold >= 0 && GetBossHealth() <= HealthThreshold && bThresholdActive && HasControl())
		{
			NetReachedThreshold();
		}

		if (bIsThirdPhase)
		{
			FQuat TargetQuat = (TargetPlayer.ActorLocation - ActorLocation)
								.GetSafeNormal().VectorPlaneProject(FVector::UpVector)
								.ToOrientationQuat();

			AcceleratedRotation.AccelerateTo(TargetQuat, 1.0, DeltaSeconds);
			SetActorRotation(AcceleratedRotation.Value);
		}
	}

	UFUNCTION()
	void SetLookTarget(AHazePlayerCharacter Player)
	{
		TargetPlayer = Player;
	}

	UFUNCTION(NetFunction)
	void NetReachedThreshold()
	{
		bThresholdActive = false;
		ThresholdReached.ExecuteIfBound();
		OnReachedThreshold();
	}

	void OnReachedThreshold()
	{
	}

	UFUNCTION(BlueprintCallable)
	void HurtAnimDone()
	{
		OnHurtAnimDone.Broadcast();
	}

	bool IsDead() const
	{
		return !bThresholdActive;
	}

	UFUNCTION(DevFunction)
	void DevTriggerHealthThreshold()
	{
		SetCurrentBossHealth(HealthThreshold);
		NetReachedThreshold();
	}
}

class AMeltdownBossWeakPoint : AHazeActor
{
	UPROPERTY(EditAnywhere)
	AMeltdownBoss Boss;
	UPROPERTY(EditAnywhere)
	FName SocketName;
	UPROPERTY(EditAnywhere)
	float WeakPointHealth = 4.0;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponseComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTarget;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachToComponent(Boss.Mesh, SocketName, EAttachmentRule::KeepWorld);
		GlitchResponseComp.OnGlitchHit.AddUFunction(this, n"OnGlitchHit");
		AutoAimTarget.TargetShape = FHazeShapeSettings::MakeSphere(Collision.ScaledSphereRadius * 0.6);
	}

	UFUNCTION()
	private void OnGlitchHit(FMeltdownGlitchImpact Impact)
	{
		auto Settings = UMeltdownGlitchShootingSettings::GetSettings(Impact.FiringPlayer);
		float Damage = 1.0;

		Boss.HealthComponent.Damage(Damage);
		Boss.HitReact();

		WeakPointHealth -= Damage;
		if (WeakPointHealth <= 0.0)
			DestroyActor();
	}

};
