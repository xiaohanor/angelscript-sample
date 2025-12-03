class UAnimInstanceDarkSlugCompanion : UAnimInstanceAIBase	
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Locomotion;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData AdditiveBanking;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Dash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData BankingAdditive;

	// Custom Variables

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	bool bShouldGlide = false;

	UPROPERTY()
	float GlideBlendValue = 0;

	FTimerHandle GlideTimer;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
		
		Velocity.X = SpeedRight;
		Velocity.Y = SpeedForward;
		Velocity.Z = SpeedUp;
		
		
	}

	UFUNCTION()
	void AnimNotify_EnterFlyState()
	{
		GlideBlendValue = 0;
		float RndGlideTimer = Math::RandRange(3.0, 10.0);
		GlideTimer = Timer::SetTimer(this, n"ShouldGlide", RndGlideTimer);
	}

	UFUNCTION()
	void AnimNotify_LeftFlyState()
	{
		GlideTimer.ClearTimer();
	}

	UFUNCTION()
	void ShouldGlide()
	{
		GlideBlendValue = 1;
		GlideTimer = Timer::SetTimer(this, n"AnimNotify_EnterFlyState", Math::RandRange(1.0, 3.0));
	}
}