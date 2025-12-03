class UPlayerDroneAudioMovementCapability : UHazePlayerCapability
{
	UDroneComponent DroneComp;
	UPlayerMovementAudioComponent MoveAudioComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UDroneComponent::Get(Player);	
		MoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DroneComp.IsPossessed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DroneComp.IsPossessed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Falling);
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Footsteps);
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::HandTrace);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Falling);
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Footsteps);
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::HandTrace);
	}
}