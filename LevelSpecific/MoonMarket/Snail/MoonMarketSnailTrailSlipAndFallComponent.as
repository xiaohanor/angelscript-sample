//don't question it
class UMoonMarketSnailTrailSlipAndFallComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	const FHazePlaySlotAnimationParams SlipAnimation;

	UPROPERTY(EditDefaultsOnly)
	const FHazePlaySlotAnimationParams RiseAnimation;

	UPROPERTY(EditDefaultsOnly)
	UPlayerFloorMotionSettings FloorSettings;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFSlip;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	const float SlipDuration = 1.5;

	AHazePlayerCharacter Player;

	bool bIHaveFallenAndICantGetUp = false;

	FVector LastSlipLocation = FVector::UpVector * 1000;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void Slip(FVector Location)
	{
		LastSlipLocation = Location;
		bIHaveFallenAndICantGetUp = true;
		Player.ApplySettings(FloorSettings, this);
	}

	void StopSlipping()
	{
		LastSlipLocation = Player.ActorLocation;
		bIHaveFallenAndICantGetUp = false;
		Player.ClearSettingsByInstigator(this);
	}

	void ResetSlipLocation()
	{
		LastSlipLocation = FVector::UpVector * 1000;
	}
};