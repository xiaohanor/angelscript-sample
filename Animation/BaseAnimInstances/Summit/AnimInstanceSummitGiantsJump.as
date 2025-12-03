
class UAnimInstanceSummitGiantsJump : UHazeAnimInstanceBase
{
	// Animations

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Kick;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData KickMh;

	

	

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