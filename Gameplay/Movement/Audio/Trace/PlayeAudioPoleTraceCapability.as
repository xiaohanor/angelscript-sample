// class UPlayerAudioPoleTraceCapability : UHazePlayerCapability
// {
// 	UPlayerPoleClimbComponent PoleComp;
// 	UFootstepTraceComponent TraceComp;
// 	UPlayerMovementAudioComponent MoveAudioComp;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
// 		PoleComp = UPlayerPoleClimbComponent::Get(Player);
// 		TraceComp = UFootstepTraceComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!PoleComp.IsClimbing())
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(PoleComp.IsClimbing())
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		MoveAudioComp.SetOverrideFootstepTraceSocket(true, LeftFootBoneName, RightFootBoneName);
// 		TraceComp.SetOverrideFootstepTraceLength(true, 15);

// 		TraceComp.SetOverrideHandTraceLength(true, 7.5, EHandType::Left);
// 		TraceComp.SetOverrideHandTraceLength(true, 2.98, EHandType::Right);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		TraceComp.SetOverrideHandTraceLength(true, 7, EHandType::Left);
// 		TraceComp.SetOverrideHandTraceLength(true, 2.98, EHandType::Right);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		MoveAudioComp.SetOverrideFootstepTraceSocket(false);
// 		TraceComp.SetOverrideFootstepTraceLength(false);
// 		TraceComp.SetOverrideHandTraceLength(false);
// 	}

// }