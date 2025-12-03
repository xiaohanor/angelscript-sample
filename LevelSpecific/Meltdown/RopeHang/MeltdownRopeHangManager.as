class AMeltdownRopeHangManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void ActivateRopeHang(USceneComponent AttachTo)
	{
		for (auto Player : Game::Players)
		{
			RequestComp.StartInitialSheetsAndCapabilities(Player, this);

			auto Comp = UMeltdownRopeHangPlayerComponent::Get(Player);
			Comp.bRopeHangActive = true;
			Comp.ActiveAttachment = AttachTo;
		}
	}
};