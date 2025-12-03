class AEvergreenStartPlayerIndicatorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	AGrapplePoint Grapple;

	UPROPERTY(EditAnywhere)
	AHazeCameraVolume StartingCameraVolume;

	TPerPlayer<bool> bWasBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingCameraVolume.OnEntered.AddUFunction(this, n"OnEntered");
		Grapple.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPointEvent");
	}

	UFUNCTION()
	private void OnEntered(UHazeCameraUserComponent User)
	{
		auto Player = Cast<AHazePlayerCharacter>(User.Owner);
		
		if (Player == nullptr)
			return;

		if (bWasBlocked[Player])
			return;

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		bWasBlocked[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPointEvent(AHazePlayerCharacter Player,
	                                                  UGrapplePointBaseComponent TargetedGrapplePoint)
	{
		if (!bWasBlocked[Player])
			return;

		bWasBlocked[Player] = false;
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
	}
};