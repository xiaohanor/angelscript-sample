
class UAnimInstanceSummitGiantsSwinging : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MhRelaxed;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MhReady;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Kick;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Throw;

	// FeatureTags and SubTags



    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        
    }
}