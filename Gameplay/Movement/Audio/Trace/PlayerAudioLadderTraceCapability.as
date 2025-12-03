// class UPlayerAudioLadderTraceCapability : UHazePlayerCapability
// {
// 	const FName LeftFootBoneName = n"LeftFootToeAudioTrace";
// 	const FName RightFootBoneName = n"RightFootToeAudioTrace";

// 	UPlayerLadderComponent LadderComp;
// 	UFootstepTraceComponent TraceComp;
// 	UPlayerMovementAudioComponent MoveAudioComp;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
// 		LadderComp = UPlayerLadderComponent::Get(Player);
// 		TraceComp = UFootstepTraceComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!LadderComp.Data.bAttachedToLadder)
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(LadderComp.Data.bAttachedToLadder)
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		MoveAudioComp.SetOverrideFootstepTraceSocket(true, LeftFootBoneName, RightFootBoneName);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		MoveAudioComp.SetOverrideFootstepTraceSocket(false);
// 	}

// }