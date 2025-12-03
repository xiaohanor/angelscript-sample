


UCLASS(Abstract)
class ATeenDragonAcidPuddle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Zone;
	default Zone.SetBoxExtent(FVector(100, 100, 10));
	default Zone.SetCollisionProfileName(n"Trigger");

	private TArray<AHazePlayerCharacter> OverlappingDragons;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Zone.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapZone");
		Zone.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapZone");
	}

	// Called when the dragon in grounded on the puddle in the puddle zone
	UFUNCTION(BlueprintEvent, DisplayName = "On Puddle Enter")
	private void BP_OnPuddleEnter(AHazePlayerCharacter Dragon) {};

	// Called when the dragon leaves the puddle
	UFUNCTION(BlueprintEvent, DisplayName = "On Puddle Exit")
	private void BP_OnPuddleExit(AHazePlayerCharacter Dragon) {};


	UFUNCTION(NotBlueprintCallable)
    private void BeginOverlapZone(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		//auto Dragon = UPlayerTeenDragonComponent::Get(Player).TeenDragon;

		// if (Dragon == nullptr)
		// 	return;

		auto PuddleComp = UTeenDragonAcidPuddleContainerComponent::Get(Player);
		if (PuddleComp == nullptr)
			return;
		
		OverlappingDragons.Add(Player);
		PuddleComp.OverlappingPuddles.Add(this);

		FTeenDragonAcidPuddleEnterVFXData EffectData;
		EffectData.Location = Player.ActorLocation;
		EffectData.Player = Player;
		UTeenDragonAcidPuddleVFXHandler::Trigger_OnPuddleEnter(Player, EffectData);

		BP_OnPuddleEnter(Player);
    }

    UFUNCTION(NotBlueprintCallable)
    private void EndOverlapZone(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		auto PuddleComp = UTeenDragonAcidPuddleContainerComponent::Get(Player);
		if (PuddleComp == nullptr)
			return;

		OverlappingDragons.RemoveSingleSwap(Player);
		PuddleComp.OverlappingPuddles.RemoveSingleSwap(this);

		FTeenDragonAcidPuddleExitVFXData EffectData;
		EffectData.Location = Player.ActorLocation;
		EffectData.Player = Player;
		UTeenDragonAcidPuddleVFXHandler::Trigger_OnPuddleExit(Player, EffectData);

		BP_OnPuddleExit(Player);
    }
}
