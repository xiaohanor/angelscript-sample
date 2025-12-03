struct FDentistBossToggleCameraActivationParams
{
	bool bToggleOn = false;
	UHazeCameraComponent CameraToToggle;
	EHazeSelectPlayer PlayersToToggle;
	float BlendTime;
	EHazeCameraPriority CameraPrio;
}

class UDentistBossToggleCameraCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossToggleCameraActivationParams Params;

	ADentistBoss Dentist;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToggleCameraActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<AHazePlayerCharacter> PlayersToToggle;
		if(Params.PlayersToToggle == EHazeSelectPlayer::Mio)
			PlayersToToggle.Add(Game::Mio);
		else if(Params.PlayersToToggle == EHazeSelectPlayer::Zoe)
			PlayersToToggle.Add(Game::Zoe);
		else if(Params.PlayersToToggle == EHazeSelectPlayer::Both)
		{
			for(auto Player : Game::Players)
			{
				PlayersToToggle.Add(Player);
			}
		}
		if(Params.bToggleOn)
		{
			for(auto Player : PlayersToToggle)
			{
				Player.ActivateCamera(Params.CameraToToggle, Params.BlendTime, Dentist, Params.CameraPrio);
			}
		}
		else
		{
			for(auto Player : PlayersToToggle)
			{
				Player.DeactivateCameraByInstigator(Dentist, Params.BlendTime);
			}
		}
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};