class ASummitKnightIntroManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditInstanceOnly)
	AAISummitKnight Knight;

	UPROPERTY(EditInstanceOnly)
	AActor DoorBlocker;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Knight.AddActorDisable(this);
		if (DoorBlocker != nullptr)
			DoorBlocker.AddActorDisable(this);
	}

	UFUNCTION()
	void EnableKnight()
	{
		Knight.RemoveActorDisable(this);
		auto DragonComp = UPlayerAcidTeenDragonComponent::Get(Game::Mio);
		DragonComp.bNonOffsetAimCamera = true;
	}

	UFUNCTION()
	void EnableDoorBlocker()
	{
		if (DoorBlocker != nullptr)
			DoorBlocker.RemoveActorDisable(this);
	}
};