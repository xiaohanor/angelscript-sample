class USummitKnightFlailComponent : UStaticMeshComponent
 {
	default CollisionProfileName = n"NoCollision";
	default bCanEverAffectNavigation = false;

	UCableComponent Chain;

	void Initialize()
	{
		TArray<UCableComponent> Cables;
		GetChildrenComponentsByClass(UCableComponent, false, Cables);
		Chain = Cables[0];
	}

	void Equip()
	{
		SetHiddenInGame(false);
		Chain.SetHiddenInGame(false);
	}

	void Unequip()
	{
		SetHiddenInGame(true);
		Chain.SetHiddenInGame(true);
	}
 }

class USummitKnightFlailBombLauncher : UBasicAIProjectileLauncherComponent
{
}

class ASummitKnightFlailBomb : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitMeltPartComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	default MeltComp.DefaultMeltSettings = SummitKnightFlailBombMeltSettings;

	UPROPERTY(DefaultComponent)
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.RelativeLocation = FVector(0.0, 0.0, 150.0);
	default AutoAimComp.AutoAimMaxAngle = 45.0;
	default AutoAimComp.TargetShape.SphereRadius = 250.0;
	default AutoAimComp.bOnlyValidIfAimOriginIsWithinAngle = false;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent PlayerCollision;
	default PlayerCollision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default PlayerCollision.CapsuleHalfHeight = 250.0;
	default PlayerCollision.CapsuleRadius = 250.0;


	// To be able to hit even when aiming high, we need both a collision component 
	// stretching above flail and an acid response component which encapsulates any 
	// impact point on collision.
	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent AcidCollision;
	default AcidCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default AcidCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default AcidCollision.RelativeLocation = FVector(0.0, 0.0, 250.0);
	default AcidCollision.CapsuleHalfHeight = 500.0;
	default AcidCollision.CapsuleRadius = 300.0;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;
	default AcidResponseComp.Shape = FHazeShapeSettings::MakeCapsule(300.0, 500.0);
	default AcidResponseComp.RelativeLocation = FVector(0.0, 0.0, 250.0);

	USummitKnightSettings Settings;
	float ExplodeTime;
	bool bPrimed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		if (MeltComp.bMelted)
		{
			USummitKnightFlailBombEventHandler::Trigger_OnMelted(this);
			ProjectileComp.Expire();
		}
	}

	void Spawn(USceneComponent Parent)
	{
		RootComponent.AttachToComponent(Parent);
		ExplodeTime = BIG_NUMBER;
		bPrimed = false;
	}

 	void Prime()
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		RootComponent.DetachFromParent(true);
		USummitKnightFlailBombEventHandler::Trigger_OnPrimeForExplosion(this);
		ExplodeTime = Time::GameTimeSeconds + Settings.FlailSmashExplosionDuration;
		bPrimed = true;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeltComp.Update(DeltaTime);

		if (!ProjectileComp.bIsLaunched)
			return;

		if (Time::GameTimeSeconds > ExplodeTime)
		{
			// Blam!
			USummitKnightFlailBombEventHandler::Trigger_OnExplode(this);
			ProjectileComp.Expire();
		}		
	}
}

asset SummitKnightFlailBombMeltSettings of USummitMeltSettings
{
	MaxHealth = 1.5;
}

UCLASS(Abstract)
class USummitKnightFlailBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPrimeForExplosion() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMelted() {}
}
