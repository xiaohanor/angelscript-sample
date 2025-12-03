

struct FTeenDragonTailBombImpactResonseData
{
	AHazeActor Bomb;
}

event void FTeenDragonTailBombExplodeEvent(FTeenDragonTailBombImpactResonseData Data);

class UTeenDragonTailBombImpactResponseComponent : USceneComponent
{
	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FTeenDragonTailBombExplodeEvent OnExplodedEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto BombCarrierComponent = UTeenDragonTailBombCarrierComponent::GetOrCreate(Game::GetZoe());
		if(!GetOwner().IsActorDisabled())
			BombCarrierComponent.ImpactResponeseComponents.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto BombCarrierComponent = UTeenDragonTailBombCarrierComponent::Get(Game::GetZoe());
		if(BombCarrierComponent != nullptr)
			BombCarrierComponent.ImpactResponeseComponents.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		auto BombCarrierComponent = UTeenDragonTailBombCarrierComponent::GetOrCreate(Game::GetZoe());
		BombCarrierComponent.ImpactResponeseComponents.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto BombCarrierComponent = UTeenDragonTailBombCarrierComponent::Get(Game::GetZoe());
		if(BombCarrierComponent != nullptr)
			BombCarrierComponent.ImpactResponeseComponents.RemoveSingleSwap(this);
	}

	void TriggerExplosionResponse(AHazeActor Bomb)
	{
		OnExploded(Bomb);

		FTeenDragonTailBombImpactResonseData EventData;
		EventData.Bomb = Bomb;
		OnExplodedEvent.Broadcast(EventData);
	}

	UFUNCTION(BlueprintEvent)
	protected void OnExploded(AHazeActor Bomb)
	{
		
	}

}