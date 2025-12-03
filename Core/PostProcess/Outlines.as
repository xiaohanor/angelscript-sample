struct FOutline
{
    UPROPERTY()
	EStencilEffectType Type = EStencilEffectType::Outline;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    FLinearColor Color = FLinearColor(0.651, 0.196, 0.235, 1.0);

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    float BorderOpacity = 0.9;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    float FillOpacity = 0.5;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    EOutlineDisplayMode DisplayMode = EOutlineDisplayMode::All;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    float BorderWidth;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    int TextureIndex = 0;

    UPROPERTY(meta = (EditCondition="Type == EStencilEffectType::Outline", EditConditionHides))
    float TextureTiling = 16.0;
}

enum EOutlineDisplayMode
{
    All = 0,
    VisiblePortion = 1,
    OccludedPortion = 2,	
}

enum EOutlineViewport
{
    Mio = 0,
    Zoe = 1,
    Both = 2,
    Neither = 3,
}

class UOutlineViewerComponent : UActorComponent
{
	
};

namespace Outline
{
	asset OutlineAsset_NoOutline of UOutlineDataAsset
	{
		Data.Type = EStencilEffectType::DisableAllOutlines;
	}

	UFUNCTION()
	UOutlineDataAsset GetZoeOutlineAsset()
	{
		return UStencilEffectViewerComponent::GetOrCreate(Game::Zoe).PlayerOutline;
	}
	UFUNCTION()
	UOutlineDataAsset GetMioOutlineAsset()
	{
		return UStencilEffectViewerComponent::GetOrCreate(Game::Mio).PlayerOutline;
	}
	UFUNCTION()
	UOutlineDataAsset GetPlayerOutlineAsset(AHazePlayerCharacter Player)
	{
		return UStencilEffectViewerComponent::GetOrCreate(Player).PlayerOutline;
	}
	UFUNCTION()
	UOutlineDataAsset GetEmptyOutlineAsset()
	{
		return UStencilEffectViewerComponent::GetOrCreate(Game::Mio).EmptyOutline;
	}
	UFUNCTION()
	UOutlineDataAsset GetNoOutlineAsset()
	{
		return OutlineAsset_NoOutline;
	}

	// Adds this component to the target players outline, "extending" the player to that object.
	UFUNCTION()
	void AddToPlayerOutline(UPrimitiveComponent Target, AHazePlayerCharacter Player, FInstigator Instigator, EInstigatePriority Priority)
	{
		ApplyOutline(Target, Player.OtherPlayer, GetPlayerOutlineAsset(Player.OtherPlayer), Instigator, Priority);
	}
	// Adds this actor to the target players outline, "extending" the player to that object.
	UFUNCTION()
	void AddToPlayerOutlineActor(AActor Target, AHazePlayerCharacter Player, FInstigator Instigator, EInstigatePriority Priority)
	{
		ApplyOutlineOnActor(Target, Player.OtherPlayer, GetPlayerOutlineAsset(Player.OtherPlayer), Instigator, Priority);
	}

	// Adds this component to the target players outline, "extending" the player to that object.
	UFUNCTION()
	void RemoveFromPlayerOutline(UPrimitiveComponent Target, AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ClearOutline(Target, Player.OtherPlayer, Instigator);
	}
	// Adds this actor to the target players outline, "extending" the player to that object.
	UFUNCTION()
	void RemoveFromPlayerOutlineActor(AActor Target, AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ClearOutlineOnActor(Target, Player.OtherPlayer, Instigator);
	}




	// Applies an outline on an actor.
	UFUNCTION()
	void ApplyOutlineOnActor(AActor Target, AHazePlayerCharacter Viewport, UOutlineDataAsset Asset, FInstigator Instigator, EInstigatePriority Priority)
	{
		if(Target == nullptr)
			return;
		
		TArray<UPrimitiveComponent> PrimitiveComponents;
		Target.GetComponentsByClass(PrimitiveComponents);
		Outline::ApplyOutlineOnComponents(PrimitiveComponents, Viewport, Asset, Instigator, Priority);
	}
	// Applies an "empty" outline on an actor. This makes the actor "cut out" outlines behind it
	UFUNCTION()
	void ApplyEmptyOutlineOnActor(AActor Target, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		if(Target == nullptr)
			return;
		
		TArray<UPrimitiveComponent> PrimitiveComponents;
		Target.GetComponentsByClass(PrimitiveComponents);
		Outline::ApplyEmptyOutlineOnComponents(PrimitiveComponents, Viewport, Instigator, Priority);
	}
	// Apply an outline that disables all other outlines on the component
	UFUNCTION()
	void ApplyNoOutlineOnActor(AActor Target, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		if(Target == nullptr)
			return;
		
		TArray<UPrimitiveComponent> PrimitiveComponents;
		Target.GetComponentsByClass(PrimitiveComponents);
		Outline::ApplyNoOutlineOnComponents(PrimitiveComponents, Viewport, Instigator, Priority);
	}
	// Clears outline on an actor.
	UFUNCTION()
	void ClearOutlineOnActor(AActor Target, AHazePlayerCharacter Viewport, FInstigator Instigator)
	{
		if(Target == nullptr)
			return;

		TArray<UPrimitiveComponent> PrimitiveComponents;
		Target.GetComponentsByClass(PrimitiveComponents);
		Outline::ClearOutlineOnComponents(PrimitiveComponents, Viewport, Instigator);
	}




	// Applies an outline on an array of components.
	UFUNCTION()
	void ApplyOutlineOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Viewport, UOutlineDataAsset Asset, FInstigator Instigator, EInstigatePriority Priority)
	{
		for(UPrimitiveComponent Target : Components)
		{
			ApplyOutline(Target, Viewport, Asset, Instigator, Priority);
		}
	}
	// Applies an "empty" outline on an array of components.
	UFUNCTION()
	void ApplyEmptyOutlineOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		for(UPrimitiveComponent Target : Components)
		{
			ApplyEmptyOutline(Target, Viewport, Instigator, Priority);
		}
	}
	// Apply an outline that disables all other outlines on the component
	UFUNCTION()
	void ApplyNoOutlineOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		for(UPrimitiveComponent Target : Components)
		{
			ApplyNoOutline(Target, Viewport, Instigator, Priority);
		}
	}
	// Clears outlines on an array of components.
	UFUNCTION()
	void ClearOutlineOnComponents(TArray<UPrimitiveComponent> Components, AHazePlayerCharacter Viewport, FInstigator Instigator)
	{
		for(UPrimitiveComponent Target : Components)
		{
			ClearOutline(Target, Viewport, Instigator);
		}
	}

	
	// Applies an outline on a component.
	UFUNCTION()
	void ApplyOutline(UPrimitiveComponent Target, AHazePlayerCharacter Viewport, UOutlineDataAsset Asset, FInstigator Instigator, EInstigatePriority Priority)
	{
		StencilEffect::ApplyStencilEffect(Target, Viewport, Asset, Instigator, Priority);
	}
	// Applies an "empty" outline on a component.
	UFUNCTION()
	void ApplyEmptyOutline(UPrimitiveComponent Target, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		StencilEffect::ApplyStencilEffect(Target, Viewport, GetEmptyOutlineAsset(), Instigator, Priority);
	}
	// Apply an outline that disables all other outlines on the component
	UFUNCTION()
	void ApplyNoOutline(UPrimitiveComponent Target, AHazePlayerCharacter Viewport, FInstigator Instigator, EInstigatePriority Priority)
	{
		StencilEffect::ApplyStencilEffect(Target, Viewport, GetNoOutlineAsset(), Instigator, Priority);
	}
	// Clears outline.
	UFUNCTION()
	void ClearOutline(UPrimitiveComponent Target, AHazePlayerCharacter Viewport, FInstigator Instigator)
	{
		StencilEffect::ClearStencilEffect(Target, Viewport, Instigator);
	}
}

class UOutlineDataAsset : UDataAsset
{
	UPROPERTY()
	FOutline Data;
};

struct FOutlineAssetSlot
{
	UPROPERTY()
	UOutlineDataAsset Outline;
}

class UOutlineGroupDataAsset : UDataAsset
{
	UPROPERTY()
	TArray<FOutlineAssetSlot> Outlines;
};