class UAnimInstanceSanctuaryLavaMole : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hidden;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Appear;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Hit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FirePrep;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FireLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Exit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESanctuaryLavamoleAnimation AnimMode;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HitReactionAlpha;

	AAISanctuaryLavamole LavaMole;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDamagedThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHidden;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LavaMole = Cast<AAISanctuaryLavamole>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LavaMole == nullptr)
			return;

		const auto NewAnimMode = LavaMole.AnimationMode;
		bDamagedThisTick = NewAnimMode == ESanctuaryLavamoleAnimation::TakeDamage && AnimMode != ESanctuaryLavamoleAnimation::TakeDamage;
		AnimMode = NewAnimMode;

		if (bDamagedThisTick)
			HitReactionAlpha = 0.5;

		if (AnimMode == ESanctuaryLavamoleAnimation::IdleBelow)
		{
			HitReactionAlpha = 0;
			// Aim towards the players
			const FVector LookAtTarget = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
			RootRotation.Yaw = FRotator::MakeFromXZ(LookAtTarget - HazeOwningActor.ActorLocation, FVector::UpVector).Yaw;
		}

		bHidden = AnimMode == ESanctuaryLavamoleAnimation::None || AnimMode == ESanctuaryLavamoleAnimation::Disappear || AnimMode == ESanctuaryLavamoleAnimation::IdleBelow;
	}

	UFUNCTION()
	void AnimNotify_HitDone()
	{
		HitReactionAlpha = 0;
	}
}