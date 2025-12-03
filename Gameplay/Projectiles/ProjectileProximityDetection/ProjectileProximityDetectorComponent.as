
event void FProjectileProximitySignature(AActor Projectile);

class UProjectileProximityDetectorComponent : UProjectileProximityDetectorComponentBase
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Proximity", Meta = (ShowOnlyInnerProperties))
	FHazeShapeSettings DetectionShape;
    default DetectionShape.Type = EHazeShapeType::Sphere;
	default DetectionShape.SphereRadius = 100.0;

	UPROPERTY(Category = "Proximity")
	FProjectileProximitySignature OnProximity;

	UPROPERTY(Category = "Proximity")
	EHazeSelectPlayer DetectPlayerProjectiles = EHazeSelectPlayer::Both;

	float ProjectileProximityTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Owner.IsActorDisabled())
			return;
		Register();		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Unregister();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Register();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Unregister();
	}

	void Register()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsSelectedBy(DetectPlayerProjectiles))
			{
				UProjectileProximityManagerComponent Manager = UProjectileProximityManagerComponent::GetOrCreate(Player);				
				Manager.RegisterProximityDetector(this);
			}
		}		
	}

	void Unregister()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsSelectedBy(DetectPlayerProjectiles))
			{
				UProjectileProximityManagerComponent Manager = UProjectileProximityManagerComponent::Get(Player);				
				if (Manager != nullptr)
					Manager.UnregisterProximityDetector(this);
			}
		}		
	}

	void CheckProximity(AActor Projectile) override
	{
		if (Projectile == nullptr)
			return;

		if (DetectionShape.IsPointInside(WorldTransform, Projectile.ActorLocation))
			OnProjectileProximity(Projectile);
	}

	void OnProjectileProximity(AActor Projectile) 
	{
		ProjectileProximityTime = Time::GameTimeSeconds;
		OnProximity.Broadcast(Projectile);
	}
}