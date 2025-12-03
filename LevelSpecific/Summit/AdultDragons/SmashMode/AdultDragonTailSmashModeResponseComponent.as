event void FOnHitByTailSmashMode(FTailSmashModeHitParams Params);

struct FTailSmashModeHitParams
{
	UPROPERTY()
	UPrimitiveComponent HitComponent;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector FlyingDirection;

	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;

	UPROPERTY()
	float DamageDealt = 0.0;
}

class UAdultDragonTailSmashModeResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnHitByTailSmashMode OnHitBySmashMode;

	UPROPERTY(EditAnywhere)
	bool bShouldStopPlayer = true;

	void ActivateSmashModeHit(FTailSmashModeHitParams Params)
	{
		OnHitBySmashMode.Broadcast(Params);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!Owner.IsActorDisabled())
		{
			auto Container = UAdultDragonTailSmashModeResponseComponentContainer::GetOrCreate(Game::Zoe);
			Container.ResponseComps.Add(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto Container = UAdultDragonTailSmashModeResponseComponentContainer::GetOrCreate(Game::Zoe);
		Container.ResponseComps.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		auto Container = UAdultDragonTailSmashModeResponseComponentContainer::GetOrCreate(Game::Zoe);
		Container.ResponseComps.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(!Owner.IsActorDisabled())
		{
			auto Container = UAdultDragonTailSmashModeResponseComponentContainer::GetOrCreate(Game::Zoe);
			Container.ResponseComps.RemoveSingleSwap(this);
		}
	}
}

class UAdultDragonTailSmashModeResponseComponentContainer : UActorComponent
{
	TArray<UAdultDragonTailSmashModeResponseComponent> ResponseComps;
}