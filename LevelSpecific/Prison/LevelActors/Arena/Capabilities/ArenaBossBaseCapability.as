class UArenaBossBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AArenaBoss Boss;

	bool bResetToIdleOnDeactivation = true;

	bool bChargedUp = false;
	float ChargeUpDuration = 2.0;

	bool bWindingDown = false;
	float WindDownDuration = 2.0;
	float CurrentWindDownTime = 0.0;

	EArenaBossState RequiredState;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AArenaBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentState != RequiredState)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.CurrentState != RequiredState)
			return true;

		if (bWindingDown && CurrentWindDownTime >= WindDownDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bChargedUp = false;
		CurrentWindDownTime = 0.0;
		bWindingDown = false;

		Boss.AnimationData.bEnteringState = true;

		Boss.OnStateEntered.Broadcast(Boss.CurrentState);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bResetToIdleOnDeactivation)
			Boss.CurrentState = EArenaBossState::Idle;

		Boss.AnimationData.bExitingState = false;

		Boss.OnStateEnded.Broadcast(RequiredState);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bChargedUp)
		{
			if (ActiveDuration >= ChargeUpDuration)
				ChargedUp();

			return;
		}

		if (bWindingDown)
		{
			CurrentWindDownTime += DeltaTime;
			return;
		}
	}

	void ChargedUp()
	{
		if (bChargedUp)
			return;

		bChargedUp = true;

		Boss.AnimationData.bEnteringState = false;
	}

	void StartWindingDown()
	{
		bWindingDown = true;

		Boss.AnimationData.bExitingState = true;
	}

	bool IsChargingUpOrWindingDown()
	{
		if (!bChargedUp)
			return true;
		if (bWindingDown)
			return true;

		return false;
	}

	FArenaBossAnimationData GetAnimData()
	{
		return Boss.AnimationData;
	}

	void SetCameraChaseEnabled(bool bEnabled)
	{
		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	if (bEnabled)
		// 		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		// 	else
		// 		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		// }
	}

	void SetBossCameraCollisionEnabled(bool bEnabled)
	{
		if (bEnabled)
			Boss.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
		else
			Boss.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
	}

	FArenaBossHandData GetEffectEventHandData()
	{
		FArenaBossHandData Data;
		Data.bRightHandRemoved = Boss.bRightHandRemoved;		
		return Data;
	}
}