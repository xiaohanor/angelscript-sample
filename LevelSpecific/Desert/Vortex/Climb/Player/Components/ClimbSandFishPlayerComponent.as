UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Variable Cooking Disable Tags Collision")
class UClimbSandFishPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	AHazePlayerCharacter Player;
	USteerSandFishInteractionComponent InteractionComp;

	UClimbSandFishFollowComponent FollowedSandFishComp;
	USceneComponent FollowedComponent;
	FName FollowedBone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsInteracting() const
	{
		return InteractionComp != nullptr;
	}

	bool IsLeft() const
	{
		check(IsInteracting());
		return Player.Player == EHazePlayer::Mio;
	}

	bool IsStandingOnFish() const
	{
		if(FollowedSandFishComp == nullptr)
			return false;

		return true;
	}
};

namespace ClimbSandFish
{
	bool IsPlayerInteracting(AHazePlayerCharacter Player)
	{
		auto PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
		if(PlayerComp != nullptr)
			return PlayerComp.IsInteracting();

		return false;
	}

	bool AreBothPlayersInteracting()
	{
		return IsPlayerInteracting(Game::Mio) && IsPlayerInteracting(Game::Zoe);
	}
}