UCLASS(Abstract)
class AIslandWalkerAcidBlob : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USphereComponent DamageSphere;
	default DamageSphere.SphereRadius = 100.0;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UIslandWalkerSettings Settings;

	float OutsideYawSign = 0.0;
	float SplitYaw = 0.0;
	int RemainingSplits = 0;
	FHitResult LandedHitResult;

	UIslandWalkerAcidBlobLauncher BlobLauncher;
	USimpleMovementData Movement;

	// After this time we automatically expire
	float InertTime = 2.0;

	// Set to 0 for no gravity
	UPROPERTY(EditAnywhere)
	float Gravity = 0.0;

	FVector OriginalMeshScale;
	FHazeAcceleratedVector ScaleAcc;
	bool bInert;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Movement = MovementComponent.SetupSimpleMovementData();
		OriginalMeshScale = Mesh.GetRelativeScale3D();
		ScaleAcc.Value = OriginalMeshScale;
		SetInert();
		SetActorTickEnabled(false);
	}

	void Launch(int Splits, bool bOriginal)
	{
		Settings = UIslandWalkerSettings::GetSettings(ProjectileComp.Launcher);
		BlobLauncher = UIslandWalkerAcidBlobLauncher::Get(ProjectileComp.Launcher);
		RemainingSplits = Splits;
		Mesh.SetRelativeScale3D(OriginalMeshScale);
		ScaleAcc.Value = OriginalMeshScale;
		SplitYaw = Settings.AcidBlobSplitYaw * 0.5;
		InertTime = Time::GameTimeSeconds + Settings.AcidBlobBounceDuration;
		Mesh.RemoveComponentVisualsBlocker(this);
		RemoveActorCollisionBlock(this);
		SetActorTickEnabled(true);
		bInert = false;
		OutsideYawSign = 0.0;
		if (bOriginal)
			UIslandWalkerAcidBlobEffectHandler::Trigger_OnLaunch(this);
		ProjectileComp.Gravity = Settings.AcidBlobGravity;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Settings == nullptr)
			return;

		if (!ProjectileComp.bIsLaunched)
			return;			

		if (Time::GameTimeSeconds > InertTime)
		{
			if (!bInert && HasControl())
				Explode(); // We've been bouncing long enough
			if (Time::GameTimeSeconds > InertTime + Settings.AcidBlobExpirationDelay)
				ProjectileComp.Expire();
			return;
		}

		// Local movement, should be deterministic(ish)
		bool bIgnoreCollision = (Time::GetGameTimeSince(ProjectileComp.LaunchTime) < 0.5);
		FHitResult Hit;
		FVector NewLoc = ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, bIgnoreCollision);
		if (ShouldExplode(Hit))
		{
			SetActorLocation(NewLoc);
			Explode(); 
			return;
		}
		if (Hit.bBlockingHit)
		{
			// Bounce and/or split
			ProjectileComp.Velocity = ProjectileComp.Velocity.GetReflectionVector(Hit.ImpactNormal) * Settings.AcidBlobBounceElasticity;
			ProjectileComp.Velocity.Z = Math::Min(1200.0, ProjectileComp.Velocity.Z); 
			NewLoc += ProjectileComp.Velocity * DeltaTime * (1.0 - Hit.Time);
			NewLoc += Hit.ImpactNormal * 0.1; // Make sure we don't get stuck in surface
			if (HasControl() && RemainingSplits > 0)
				Split();
			UIslandWalkerAcidBlobEffectHandler::Trigger_OnBounce(this, FWalkerAcidBlobImpactData(Hit));
		}

		SetActorLocation(NewLoc);
	}

	bool ShouldExplode(FHitResult Hit)
	{
		if (Hit.bBlockingHit) 
		{
			if ((Hit.ImpactNormal.Z < 0.707) && HasControl())
				return true;	
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
			if ((HitPlayer != nullptr) && HitPlayer.HasControl())
				return true;
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > 0.5)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if(Player.ActorCenterLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius * 0.8))
					return true;
			}
		}
		return false;
	}

	void Explode()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(!Player.ActorLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius))
				continue;
			auto PlayerHealthComp = UPlayerHealthComponent::Get(Player);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(Settings.AcidBlobDamagePlayer, nullptr, nullptr);
		}
		SetInert();
	
		UIslandWalkerAcidBlobEffectHandler::Trigger_OnExplode(this);
	}

	void SetInert()
	{
		bInert = true;
		InertTime = Time::GameTimeSeconds;
		Mesh.AddComponentVisualsBlocker(this);
		AddActorCollisionBlock(this);
	}

	private void Split()
	{
		if (RemainingSplits == 0)
			return; // Already split from some other source

		// Spawn split
		FVector SplitVelocity = ProjectileComp.Velocity.RotateAngleAxis(-SplitYaw, FVector::UpVector);
		if (OutsideYawSign == Math::Sign(SplitYaw))
			SplitVelocity *= Settings.AcidBlobSplitSlowdown; // Insize splits slow down
		AIslandWalkerAcidBlob SplitBlob = Split(SplitVelocity); 
		SplitBlob.SplitYaw = -SplitYaw * 0.8;
		SplitBlob.RemainingSplits = RemainingSplits - 1;
		SplitBlob.OutsideYawSign = OutsideYawSign;

		// We become the other split
		ProjectileComp.Velocity = ProjectileComp.Velocity.RotateAngleAxis(SplitYaw, FVector::UpVector);
		if (OutsideYawSign == -Math::Sign(SplitYaw))
			ProjectileComp.Velocity *= Settings.AcidBlobSplitSlowdown; // Insize splits slow down
		SplitYaw *= 0.8;
		RemainingSplits--;

		if (OutsideYawSign == 0.0)
		{
			// Initial split;
			OutsideYawSign = 1.0;
			SplitBlob.OutsideYawSign = -1.0;	
		}

		UIslandWalkerAcidBlobEffectHandler::Trigger_OnSplit(this);
	}

	private AIslandWalkerAcidBlob Split(FVector Velocity)
	{
		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(Velocity, FRotator::ZeroRotator);
		auto Blob = Cast<AIslandWalkerAcidBlob>(Projectile.Owner);
		Projectile.Gravity = Settings.AcidBlobGravity;
		Projectile.UpVector = ActorUpVector;
		Blob.SetActorRotation(FRotator::MakeFromZ(ActorUpVector));
		Blob.SetActorLocation(ActorLocation);
		Blob.Launch(0, false);
		return Blob;
	}
}

class UIslandWalkerAcidBlobLauncher : UBasicAIProjectileLauncherComponent
{
}

UCLASS(Abstract)
class UIslandWalkerAcidBlobEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UNiagaraComponent BlobFX;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BlobFX = UNiagaraComponent::Get(Owner, n"BlobEffect");
		BlobFX.Deactivate();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSplit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBounce(FWalkerAcidBlobImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplode() {}
}

struct FWalkerAcidBlobImpactData
{
	UPROPERTY()
	FHitResult HitResult;

	FWalkerAcidBlobImpactData(FHitResult Impact)
	{
		HitResult = Impact;
	}
}