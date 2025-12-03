struct FAnimationMoonMarketCatAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Collected;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Floating;	
}

class UAnimInstanceMoonMarketCat : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FAnimationMoonMarketCatAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData Gestures;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCollected;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	AMoonMarketCat Cat;

	FTransform CachedActorTransform;

	float GestureTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Cat = Cast<AMoonMarketCat>(HazeOwningActor);
		CachedActorTransform = HazeOwningActor.ActorTransform;

		AnimData = Cat.Animations;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Cat == nullptr)
			return;

		bCollected = Cat.SoulTargetPlayer != nullptr;

		if (DeltaTime > 0)
		{
			RotationRate = Math::Clamp((HazeOwningActor.ActorRotation - CachedActorTransform.Rotator()).Normalized.Yaw / DeltaTime / 200, -1.0, 1.0);
			FVector Velocity = (HazeOwningActor.ActorLocation - CachedActorTransform.Location) / DeltaTime;
			Speed = Velocity.Size();

			HipsRotation.Pitch = Math::FInterpTo(HipsRotation.Pitch,
												 Math::Clamp(
													 FRotator::MakeFromXZ(Velocity, HazeOwningActor.ActorForwardVector).Pitch * Math::Clamp(Speed / 500, 0.0, 1.0),
													 -60,
													 60),
												 DeltaTime,
												 5);
		}

		CachedActorTransform = HazeOwningActor.ActorTransform;

		if (bCollected)
		{
			bPlayGesture = false;
			
			if (Speed < 50)
			{
				if (GestureTimer > 0)
				{
					GestureTimer -= DeltaTime;
					if (GestureTimer < 0)
						bPlayGesture = true;

				}
				else
					GestureTimer = Math::RandRange(4, 6);

			}
			else
				GestureTimer = -1;
		}
	}

	UFUNCTION()
	void AnimNotify_Caught()
	{
		auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		PhysComp.ApplyProfileAsset(this, PhysProfile);
	}
}