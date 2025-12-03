UFUNCTION(BlueprintCallable)
mixin void ApplyBreathingSettings(AHazePlayerCharacter Player, UPlayerBreathingAudioSettings Settings, UObject Instigator)
{
	if(Settings != nullptr && Instigator != nullptr)
	{
		Player.ApplySettings(Settings, Instigator);
	}
}

UFUNCTION(BlueprintCallable)
mixin void RemoveBreathingSettingsOverride(AHazePlayerCharacter Player, UObject Instigator)
{	
	if(Instigator != nullptr)
		Player.ClearSettingsOfClass(UPlayerBreathingAudioSettings, Instigator);
}

event void FOnStartAudioPlayerMovementTrace(FVector InStartTrace, FVector InEndTrace);
event void FOnStartAudioPlayerMovementFootstepTrace(FPlayerFootstepTraceData InFootstepData);

class UPlayerMovementAudioComponent : UHazeMovementAudioComponent
{
	AHazePlayerCharacter Player;

	private float LeftArmVeloSpeed = 0.0;
	private float RightArmVeloSpeed = 0.0;

	private TMap<EHandType, bool> SlidingHands;
	default SlidingHands.Add(EHandType::Left, false);
	default SlidingHands.Add(EHandType::Right, false);

	private FHandTraceData LeftHandTraceData;
	private FHandTraceData RightHandTraceData;

	#if TEST
	UPhysicalMaterialAudioAsset DebugLeftFootMaterial = nullptr;
	UPhysicalMaterialAudioAsset DebugRightFootMaterial = nullptr;
	#endif

	private FName LeftFootTracePosSocketName = MovementAudio::Player::LeftFootBoneName;
	private FName RightFootTracePosSocketName = MovementAudio::Player::RightFootBoneName;

	private bool bDefaultPlayerMovementBlocked = false;
	private TArray<FInstigator> BlockDefaultPlayerMovementInstigators;

	FOnStartAudioPlayerMovementFootstepTrace OnFootTrace;
	FOnStartAudioPlayerMovementTrace OnFootSlideTrace;

	void RequestBlockDefaultPlayerMovement(FInstigator Instigator)
	{
		BlockDefaultPlayerMovementInstigators.AddUnique(Instigator);
		bDefaultPlayerMovementBlocked = true;
	}

	void UnRequestBlockDefaultPlayerMovement(FInstigator Instigator)
	{
		BlockDefaultPlayerMovementInstigators.RemoveSingleSwap(Instigator);
		bDefaultPlayerMovementBlocked = BlockDefaultPlayerMovementInstigators.Num() > 0;
	}

	bool IsDefaultMovementBlocked() const
	{
		return bDefaultPlayerMovementBlocked;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());		
	}

	// FHandTraceData& GetTraceData(const EHandType HandType)
	// {
	// 	if(HandType == EHandType::Left)
	// 		return LeftHandTraceData;

	// 	return RightHandTraceData;
	// }	

	// void SetOverrideFootstepTraceSocket(bool bIsSet, const FName& LeftSocketName = NAME_None, const FName& RightSocketName = NAME_None)
	// {
	// 	if(bIsSet)
	// 	{
	// 		if(LeftSocketName != NAME_None)
	// 			LeftFootTracePosSocketName = LeftSocketName;

	// 		if(RightSocketName != NAME_None)
	// 			RightFootTracePosSocketName = RightSocketName;
	// 	}
	// 	else
	// 	{
	// 		LeftFootTracePosSocketName = MovementAudio::Player::LeftFootBoneName;
	// 		RightFootTracePosSocketName = MovementAudio::Player::RightFootBoneName;
	// 	}		
	// }

	void AddHandSliding(const EHandType Hand)
	{
		SlidingHands[Hand] = true;
	}

	void RemoveHandSliding(const EHandType Hand)
	{
		SlidingHands[Hand] = false;
	}

	bool AnyHandSliding()
	{
		return SlidingHands[EHandType::Left] || SlidingHands[EHandType::Right];
	}

	bool IsHandSliding(const EHandType Hand)
	{
		return SlidingHands[Hand];
	}

	void SetHandVeloSpeed(const EHandType& Hand, const float InSpeed)
	{
		if(MovementAudio::IsLeftHand(Hand))
			LeftArmVeloSpeed = InSpeed;

		RightArmVeloSpeed = InSpeed;
	}

	float GetHandVeloSpeed(const EHandType& Hand)
	{
		if(MovementAudio::IsLeftHand(Hand))
			return LeftArmVeloSpeed;

		return RightArmVeloSpeed;
	}

}
