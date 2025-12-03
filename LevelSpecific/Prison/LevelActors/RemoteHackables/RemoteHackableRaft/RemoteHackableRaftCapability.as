class URemoteHackableRaftCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableRaft Raft;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Raft = Cast<ARemoteHackableRaft>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Raft.UpdatePlayerInput(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector Input = PlayerMoveComp.MovementInput;
			Raft.UpdatePlayerInput(Input);

			float FFFrequency = Math::GetMappedRangeValueClamped(FVector2D(200.0, Raft.MoveSpeed), FVector2D(0.0, 30.0), MoveComp.HorizontalVelocity.Size());
			float FFIntensity = Math::GetMappedRangeValueClamped(FVector2D(200.0, Raft.MoveSpeed), FVector2D(0.0, 0.15), MoveComp.HorizontalVelocity.Size());

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
			Player.SetFrameForceFeedback(FF);
		}
	}
}