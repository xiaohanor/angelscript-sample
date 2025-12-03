// Holds info for player to access
class USplineFocusCameraBlendPlayerComponent : UActorComponent
{
	UPROPERTY(Transient)
	USegmentedSplineFocusCameraBlendComponent SplineFocusCameraBlendComponent;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsSplineFocusCameraActive() const
	{
		if (SplineFocusCameraBlendComponent == nullptr)
			return false;

		if (!SplineFocusCameraBlendComponent.IsFocusBlendActiveForPlayer(PlayerOwner))
			return false;

		return true;
	}
}