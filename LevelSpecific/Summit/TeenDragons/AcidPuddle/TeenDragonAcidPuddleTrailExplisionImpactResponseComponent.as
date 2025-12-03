
event void FPuddleTrailOnExplodedSignature(ATeenDragonAcidPuddleTrail FromTrail);

/** Global getter for the container */
namespace FTeenDragonAcidPuddle
{
	UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer GetPuddleExplosionResponseComponentContainer()
	{
		return UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer::Get(Game::GetMio());
	}
}

/** Container for all the response components */
UCLASS(NotPlaceable, NotBlueprintable)
class UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer : UActorComponent
{
	TArray<UTeenDragonAcidPuddleTrailExplosionResponseComponent> Components;
}

/** Response component */
class UTeenDragonAcidPuddleTrailExplosionResponseComponent : USceneComponent
{
	// How far away from the trail we need to be
	UPROPERTY(Category = "Settings")
	float ResponseRadius = 300;

	UPROPERTY(Category = "Events")
	FPuddleTrailOnExplodedSignature OnTrailExploded;

	private UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer Container;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!Owner.IsActorDisabled())
		{
			if(Container == nullptr)
				Container = UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer::GetOrCreate(Game::GetMio());
			Container.Components.Add(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(Container != nullptr)
			Container.Components.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(Container != nullptr)
			Container.Components.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(Container == nullptr)
			Container = UTeenDragonAcidPuddleTrailExplosionResponseComponentContainer::GetOrCreate(Game::GetMio());
		Container.Components.Add(this);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "On Trail Exploded")
	void BP_OnTrailExploded(ATeenDragonAcidPuddleTrail FromTrail)
	{

	}

	void TriggerOnTrailExplosion(ATeenDragonAcidPuddleTrail FromTrail)
	{
		BP_OnTrailExploded(FromTrail);
		OnTrailExploded.Broadcast(FromTrail);
	}
};

#if EDITOR
class UTeenDragonAcidPuddleTrailExplosionResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTeenDragonAcidPuddleTrailExplosionResponseComponent;
	
    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto ResponseComp = Cast<UTeenDragonAcidPuddleTrailExplosionResponseComponent>(Component);
        if (ResponseComp == nullptr)
            return;

		DrawWireSphere(ResponseComp.WorldLocation, ResponseComp.ResponseRadius, FLinearColor::Red, 2);	
    }
}
#endif