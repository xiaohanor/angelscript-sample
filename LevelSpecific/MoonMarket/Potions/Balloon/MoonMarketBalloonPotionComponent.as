UCLASS(Abstract)
class UMoonMarketBalloonPotionComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UHazeComposableSettings GravitySetting;

	UPROPERTY(EditDefaultsOnly)
	FHazePlayOverrideAnimationParams OverrideAnimation;

	UPROPERTY(EditDefaultsOnly)
	const float BounceStrength = 700;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysAnimProfile;

	UPROPERTY(EditDefaultsOnly)
	const float Radius = 100; //How big the balloon is, used for calculating rotation speed (larger value means slower rotation)
	
	UPROPERTY()
	FHazePlaySlotAnimationParams InteractionAnimation;

	UPROPERTY()
	TPerPlayer<USkeletalMesh> Meshes;

	UPROPERTY()
	TPerPlayer<USkeletalMesh> DefaultPlayerMeshes;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMoonMarketCandyBalloonForm> BalloonFormClass;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BounceForceFeedback;

	private UHazeCapabilitySheet CurrentActiveSheet;

	AHazePlayerCharacter Player;
	UMoonMarketShapeshiftComponent ShapeshiftComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShapeshiftComponent = UMoonMarketShapeshiftComponent::GetOrCreate(Player);
	}

	void BeginInteraction(AMoonMarketBalloonCandy Potion)
	{
		CurrentActiveSheet = Potion.SheetToStartWhenConsumed;

		//IF player was about to morph into something, make sure to cancel this
		UPolymorphResponseComponent::Get(Owner).DesiredMorphClass = nullptr;

		Player.StartCapabilitySheet(CurrentActiveSheet, this);
	}

	void StopCurrentInteraction()
	{
		if(CurrentActiveSheet == nullptr)
			return;

		Player.StopCapabilitySheet(CurrentActiveSheet, this);
		CurrentActiveSheet = nullptr;
	}

	bool IsBalloonFormActive() const
	{
		return CurrentActiveSheet != nullptr;
	}
};