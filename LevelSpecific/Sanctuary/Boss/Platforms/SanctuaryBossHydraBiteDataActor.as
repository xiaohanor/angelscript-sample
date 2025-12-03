class ASanctuaryBossHydraBiteDataActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossHydraHead HydraHeadActor;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform PlatformActor;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryBossHydraTelegraphComponent TelegraphComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SendBiteData()
	{
		auto HydraBase = Hydra::GetHydraBase();
		if (HydraBase == nullptr)
			return;
		
		HydraBase.TriggerSmash(PlatformActor.Root.WorldLocation, PlatformActor.Root, TelegraphComp, 1.0, 0.5, HydraHeadActor.Identifier);
	}
};