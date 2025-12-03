class ASidescrollCameraManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	ABothPlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor Camera;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnBothPlayersInside.AddUFunction(this, n"OnBothPlayersInside");
	}

	//Testing without
	UFUNCTION()
	private void OnBothPlayersInside()
	{
		// auto TargetComp = UCameraWeightedTargetComponent::Get(Camera);

		// for (AHazePlayerCharacter Player : Game::Players)
		// {
		// 	//This blends weirdly
		// 	TargetComp.ApplyWorldOffset(Player, FVector(0,0,150.0), this, EHazeCameraPriority::High);
		// }
	}
};