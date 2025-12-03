class UAnimInstanceMeltdownScreenPushRader : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LeftHandPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RightHandPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RightHandRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator LeftHandRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayRaderIdle;

	UPROPERTY(Interp, EditAnywhere)
	bool bEnableIKHandLeft = false;

	UPROPERTY(Interp, EditAnywhere)
	bool bEnableIKHandRight = false;

	const FVector HAND_OFFSET_LEFT = FVector(0, -2, 25);
	const FVector HAND_OFFSET_RIGHT = FVector(0, 2, 30);

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (GetWorld().IsGameWorld())
		{
			auto PushManager = TListedActors<AMeltdownScreenPushManager>().GetSingle();
			if (PushManager != nullptr)
			{
				LeftHandPosition = PushManager.RaderLeftHandPosition + HAND_OFFSET_LEFT;
				RightHandPosition = PushManager.RaderRightHandPosition + HAND_OFFSET_RIGHT;
				LeftHandRotation = PushManager.RaderLeftHandRotation;
				RightHandRotation = PushManager.RaderRightHandRotation;

				bPlayRaderIdle = PushManager.bPlayRaderIdle;

				bEnableIKHandLeft = PushManager.bRaderEnableIKHandLeft;
				bEnableIKHandRight = PushManager.bRaderEnableIKHandRight;
			}
		}
	}

}