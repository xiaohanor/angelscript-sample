UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ASkylineGravityPanelEnablementVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	/**
	 * These gravity panels will _only_ be enabled if the player is inside this volume.
	 */
	UPROPERTY(EditAnywhere, Category = "Gravity Panels")
	TArray<ASkylineGravityPanel> GravityPanels;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASkylineGravityPanel Panel : GravityPanels)
		{
			if (Panel != nullptr)
				Panel.GravityBladeGrappleComponent.Disable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if (OtherActor != Game::Mio)
			return;

		for (ASkylineGravityPanel Panel : GravityPanels)
		{
			if (Panel != nullptr)
				Panel.GravityBladeGrappleComponent.Enable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if (OtherActor != Game::Mio)
			return;
		
		for (ASkylineGravityPanel Panel : GravityPanels)
		{
			if (Panel != nullptr)
				Panel.GravityBladeGrappleComponent.Disable(this);
		}
	}
};