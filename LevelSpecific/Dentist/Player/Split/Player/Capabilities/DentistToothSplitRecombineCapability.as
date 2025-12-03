struct FDentistToothSplitRecombineActivateParams
{
	float RecombineDuration = 0.0;
};

/**
 * Checks if the player has reached the AI controlled half, and if so, starts recombining into one tooth
 */
class UDentistToothSplitRecombineCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	
	UDentistToothPlayerComponent PlayerComp;
	UDentistToothSplitComponent SplitComp;
	UDentistToothJumpComponent JumpComp;

	FVector LocationOffset;
	FQuat InitialRotation;
	float RecombineDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		SplitComp = UDentistToothSplitComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothSplitRecombineActivateParams& Params) const
	{
		if(!SplitComp.bIsSplit)
			return false;

		if(Time::GetGameTimeSince(SplitComp.SplitStartTime) < Dentist::SplitTooth::MinSplitDuration)
			return false;

		ADentistSplitToothAI SplitToothAI = SplitComp.GetSplitToothAI();
		switch(SplitToothAI.State)
		{
			case EDentistSplitToothAIState::Splitting:
				return false;

			case EDentistSplitToothAIState::Startled:
				return false;

			default:
				break;
		}

		const float Distance = SplitToothAI.ActorCenterLocation.Distance(Player.ActorCenterLocation);
		if(Distance > Dentist::SplitTooth::RecombineDistance)
			return false;

		Params.RecombineDuration = (Distance * 0.5) / Dentist::SplitTooth::RecombineSpeed;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplitComp.bIsSplit)
			return true;

		if(ActiveDuration > RecombineDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothSplitRecombineActivateParams Params)
	{
		RecombineDuration = Params.RecombineDuration;

		ADentistSplitToothAI SplitToothAI = SplitComp.GetSplitToothAI();
		SplitToothAI.State = EDentistSplitToothAIState::Recombining;

		LocationOffset = SplitToothAI.ActorLocation - Player.ActorLocation;
		InitialRotation = SplitToothAI.ActorQuat;

		FDentistToothSplitEventHandlerOnStartRecombineEventData EventData;
		EventData.PlayerTransform = Player.CapsuleComponent.WorldTransform;
		EventData.AITransform = SplitToothAI.CollisionComp.WorldTransform;
		UDentistToothEventHandler::Trigger_OnStartRecombine(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ADentistSplitToothAI SplitToothAI = SplitComp.GetSplitToothAI();
		SplitToothAI.State = EDentistSplitToothAIState::Inactive;
		SplitComp.bShouldSplit = false;

		FDentistToothSplitEventHandlerOnFinishRecombineEventData EventData;
		EventData.RecombineTransform = Player.CapsuleComponent.WorldTransform;
		UDentistToothEventHandler::Trigger_OnFinishRecombine(Player, EventData);

		JumpComp.bForceFrontFlipJump = true;

		// Zero out horizontal velocity so that the jump does't throw you over the edge
		Player.SetActorVelocity(Player.ActorVerticalVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / RecombineDuration);
		Alpha = Math::EaseOut(0, 1, Alpha, 2.0);

		FVector Offset = Math::Lerp(LocationOffset, FVector::ZeroVector, Alpha);
		FQuat Rotation = FQuat::Slerp(InitialRotation, Player.Mesh.ComponentQuat, Alpha);

		SplitComp.SplitToothAI.SetActorLocationAndRotation(
			Player.ActorLocation + Offset,
			Rotation
		);
	}
};