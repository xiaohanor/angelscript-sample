USTRUCT()
struct FGoldenApplePlayerPigAnimationData
{
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence PickupAnimation = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence CarryAnimation = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UHazeBoneFilterAsset CarryBoneFilter = nullptr;	


	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UHazeBoneFilterAsset CarryJawFilter = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	UAnimSequence CarryJawOverrideAnimation = nullptr;
}

class UGoldenApplePlayerComponent : UActorComponent
{
	UPROPERTY()
	TPerPlayer<FGoldenApplePlayerPigAnimationData> AnimationData;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FName AlignmentNodeName = n"MouthAttach";

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FName AttachNodeName = n"MouthAttach";

	AHazePlayerCharacter Player;
	AGoldenApple CurrentApple = nullptr;

	access Carry = private, UGoldenApplePlayerPickupCapability, UGoldenApplePlayerCarryCapability;
	access : Carry bool bIsCarryingApple = false;
	access : Carry bool bPlayingCarryingAnimation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void PickUpApple(AGoldenApple Apple)
	{
		CurrentApple = Apple;
	}

	UFUNCTION(BlueprintPure)
	bool IsCarryingApple() const
	{
		return bIsCarryingApple;
	}
}