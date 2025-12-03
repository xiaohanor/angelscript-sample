struct FSandHandSpawnedData
{
	UPROPERTY()
	bool bLeft;

	UPROPERTY()
	ASandHandProjectile SandHandProjectile;
}

struct FSandHandShotData
{
	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FVector InitialVelocity;

	UPROPERTY()
	USandHandAutoAimTargetComponent Target;

	UPROPERTY()
	ASandHandProjectile SandHandProjectile;
}

struct FSandHandHitData
{
	UPROPERTY()
	AHazePlayerCharacter Caster;

	UPROPERTY()
	ASandHandProjectile SandHandProjectile;

	UPROPERTY()
	UPrimitiveComponent HitComponent;

	UPROPERTY()
	FVector RelativeImpactLocation;

	UPROPERTY()
	FVector RelativeImpactNormal;
}

struct FSandHandRecycleData
{
	UPROPERTY()
	ASandHandProjectile SandHandProjectile;
}

UCLASS(Abstract)
class USandHandEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter PlayerOwner;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	USandHandPlayerComponent PlayerSandHandComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerSandHandComponent = USandHandPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSandHandSpawned(FSandHandSpawnedData SpawnedData)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSandHandShot(FSandHandShotData ShotData)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSandHandProjectileHit(FSandHandHitData HitData)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSandHandRecycled(FSandHandRecycleData RecycleData)
	{
	}

	UFUNCTION(BlueprintPure)
	ASandHandProjectile GetSandHandProjectile() const
	{
		return PlayerSandHandComponent.CurrentProjectile;
	}
}